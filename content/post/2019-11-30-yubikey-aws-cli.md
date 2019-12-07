---
title: Making life easier with Yubikeys and the AWS CLI
author: sigmaris
type: post
date: 2019-11-30T20:51:00+00:00
url: /2019/11/yubikey-aws-cli/
categories:
  - Uncategorized
tags:
  - aws
---
If you're working with Amazon Web Services, and want the highest level of security around usage of your AWS account, AWS recommends that you use IAM users instead of the account's root user, [set up Multi-Factor authentication][1] (MFA) on the IAM users, and then [require MFA for API operations][2]. Typically this requires the person performing operations on AWS to provide a one-time code when they authenticate to AWS, as well as their more permanent password (for the web console) or their Access Key (for the CLI and SDKs).

Although the AWS CLI supports MFA authentication to temporarily [assume roles][3], it doesn't currently support using MFA authentication with IAM user credentials. Also, it requires you to look up a code (e.g. from an authenticator app on your phone) and type it in to the terminal each time you want to authenticate using MFA.

With the YubiKey's support for RFC 6238 TOTP tokens (the same type of time-based one-time token that AWS uses) we can make this a much smoother process by adding some functions to our shell startup file. This guide applies to Bash and Bash-compatible shells like zsh, on Mac OS and Linux.

## Step 1: Store the MFA secret key on your YubiKey

There are a couple of ways to store the MFA secret key on your YubiKey. First you need to [set up a Virtual MFA device][4] on your IAM user account. When you get to the stage where the secret key is displayed in a QR code, you need to get this onto the YubiKey. You can use the "Scan QR code" option in the [Yubico Authenticator][5] desktop app, or you can install the `ykman` [CLI tool][6] for YubiKey, use the "Show secret key" option on AWS and then use the CLI command `ykman oath add AWS` to add the secret key. You'll need the `ykman` tool for the next step anyway.

Make a note of the Amazon Resource Name (ARN) for your "Assigned MFA device" on your IAM user account. It'll normally start with "arn:aws:iam::" and end with "mfa/yourusername". You'll need this in step 4.

## Step 2: Install the YubiKey Manager, jq and AWS CLI tools

Make sure the [YubiKey Manager CLI tool][6] is installed and on your `$PATH` so that you can enter the command `ykman` in a terminal and it'll run. Similarly, make sure the [AWS CLI tool][7] is installed and you can run the `aws` command.

With `ykman` installed and your YubiKey inserted, you should be able to run `ykman oath code` at the terminal, and see your 6-digit MFA code for AWS listed as:

    ...    111111
    AWS    123456
    ...    222222

The rest of this guide assumes you've named it "AWS" as above on the YubiKey.

Install the AWS CLI tool from [here][8]. Make sure it's on your `$PATH`, i.e. you can run the `aws` command in a terminal.

Finally, install the [jq][9] tool for extracting values from JSON, this'll be used in the functions later.

## Step 3: Save your personal AWS access keys on disk for the AWS CLI

In order to call the AWS APIs to obtain MFA-authenticated session credentials, we need to first authenticate somehow to AWS. The way to do this is to use AWS access keys, and to provide these to the AWS CLI, we need to save them to the `~/.aws/credentials` file. Run the command `aws configure`, which will prompt for your AWS Access Key ID, Secret Access Key and a few other defaults, and save them in your `~/.aws` directory.

## Step 4: test getting MFA-authenticated session credentials

Get a current 6-digit MFA code from the YubiKey, using `ykman oath code AWS`, and then run this command:

    aws sts get-session-token --serial-number <MFA device ARN> --token-code <token code> --output json

Replace `<MFA device ARN>` with your assigned MFA device ARN from step 1 above, and replace `<token code>` with the 6-digit code from the Yubikey. You should see a JSON object with AccessKeyId, SecretAccessKey and SessionToken keys.

## Step 5: Add function definitions to your shell startup file

Now let's add functions to the shell startup file to automate doing all of these commands. These functions are compatible with bash and zsh, and should be added to your .bashrc or .zshrc.

First, define a function for getting an MFA code from the YubiKey:

    function aws-get-mfa-code {
        ykman oath code AWS 2>/dev/null | sed -E 's/(None:)?AWS[[:space:]]+([[:digit:]]+)/\2/'
    }

(If you've named the stored key something other than AWS, change that part in the above function)

Then, define a function that takes an MFA code as an argument, uses the AWS CLI to get credentials for a temporary MFA-authenticated session, and sets environment variables with the credentials:

    # Replace <MFA device ARN> here with your MFA device ARN from step 1
    AWS_MFA_SERIAL="<MFA device ARN>"

    function aws-mfa-session {
        STS_CREDS=$(aws sts get-session-token --serial-number "$AWS_MFA_SERIAL" --token-code "$1" --output json)
        if [ "$?" -eq "0" ]
        then
            export AWS_ACCESS_KEY_ID=$(echo $STS_CREDS | jq -r '.Credentials.AccessKeyId')
            export AWS_SECRET_ACCESS_KEY=$(echo $STS_CREDS | jq -r '.Credentials.SecretAccessKey')
            export AWS_SECURITY_TOKEN=$(echo $STS_CREDS | jq -r '.Credentials.SessionToken')
            export AWS_SESSION_TOKEN=$(echo $STS_CREDS | jq -r '.Credentials.SessionToken')
            export AWS_SESSION_EXPIRY=$(echo $STS_CREDS | jq -r '.Credentials.Expiration')
        else
            echo "Error: Failed to obtain temporary credentials."
        fi
    }

The environment variables set here will be used by the AWS CLI and most AWS SDKs, in preference to the credentials saved on disk, so that means any subsequent AWS CLI commands or programs run in the shell session where these variables are set, will operate with those credentials.

It's also useful to be able to remove all of these environment variables, for example when the temporary credentials expire and you need to start a new session from scratch, so let's define a function to do that:

    function aws-reset-env {
        unset AWS_ACCESS_KEY_ID
        unset AWS_SECRET_ACCESS_KEY
        unset AWS_SECURITY_TOKEN
        unset AWS_SESSION_TOKEN
        unset AWS_SESSION_EXPIRY
        unset AWS_ASSUMED_ROLE_ID
        unset AWS_ASSUMED_ROLE_ARN
    }

Finally, in the spirit of UNIX, let's chain functions together to create a single command, with no required arguments, to start an MFA-authenticated session.

    function aws-yubi-session {
        aws-mfa-session $(aws-get-mfa-code)
    }

After saving these into your shell startup file, you need to start a new shell session (or `source` your .bashrc) to make these functions available.

# Bonus step 6: Assuming a role with MFA

Similarly to obtaining temporary credentials for your IAM user, you can authenticate with MFA, assume a role in your current AWS account or in another account, and set environment variables with the role's temporary credentials all in one operation, with these additional functions:

    # Usage: aws-assume-role-mfa <12-digit role account ID> <role name> <MFA code>
    function aws-assume-role-mfa {
        ASSUMED_ROLE_CREDS=$(aws sts assume-role --role-arn "arn:aws:iam::${1}:role/${2}" --role-session-name $(whoami)@$(hostname) --serial-number "$AWS_MFA_SERIAL" --token-code "$3" --output json)

        if [ "$?" -eq "0" ]
        then
            export AWS_ACCESS_KEY_ID=$(echo $ASSUMED_ROLE_CREDS | jq -r '.Credentials.AccessKeyId')
            export AWS_SECRET_ACCESS_KEY=$(echo $ASSUMED_ROLE_CREDS | jq -r '.Credentials.SecretAccessKey')
            export AWS_SESSION_TOKEN=$(echo $ASSUMED_ROLE_CREDS | jq -r '.Credentials.SessionToken')
            export AWS_SECURITY_TOKEN=$(echo $ASSUMED_ROLE_CREDS | jq -r '.Credentials.SessionToken')
            export AWS_SESSION_EXPIRY=$(echo $ASSUMED_ROLE_CREDS | jq -r '.Credentials.Expiration')

            export AWS_ASSUMED_ROLE_ID=$(echo $ASSUMED_ROLE_CREDS | jq -r '.AssumedRoleUser.AssumedRoleId')
            export AWS_ASSUMED_ROLE_ARN=$(echo $ASSUMED_ROLE_CREDS | jq -r '.AssumedRoleUser.Arn')
        else
            echo "Error: Failed to obtain temporary role credentials."
        fi
    }

    # Here's an example of how you'd then make a "shortcut" function to assume a role with YubiKey authentication
    function aws-yubi-assumemyrole {
        aws-assume-role-mfa 123456789012 MyMFARequiredRole $(aws-get-mfa-code)
    }

This is useful if your AWS account is set up in a way that people's IAM users have restricted permissions, and they have to assume a role with MFA authentication to do privileged operations.

# Notes

You can adjust the validity duration of the temporary credentials by adding a `--duration-seconds <sec>` argument to the above `aws sts ...` commands.

A useful command to show what identity you "appear as" to AWS, is `aws sts get-caller-identity` - this will show if you are operating as an IAM user or a role. It doesn't show if the session is MFA-authenticated or not, though.

If you use the AWS CLI without previously running one of the functions above to set the environment variables, it'll use the credentials saved in step 3 without MFA authentication. If you want to avoid doing this accidentally, you can instead save the credentials to disk under a different [named profile][10], for example "work", and then add a `--profile work` argument to the `aws sts ...` commands above. That way, unless you add `--profile work` to other `aws ...` commands you run, the AWS CLI tool won't find any credentials.

Why define shell functions instead of using a script? Because scripts run as subprocesses of the shell, and subprocesses can only affect their own environment variables and those of their child processes. Once the subprocesses finish, their environment variables are lost. However shell functions execute in the same process as the shell, and can set environment variables for the current shell session. There are workarounds like having a script output shell commands which can be piped to `eval`, or having a script launch subprocesses with the environment variables set, but I feel like this is quite an elegant approach to having single commands for common operations.

Altogether, hopefully these functions will save you as much time as they've saved me at work - which is probably many hours.

 [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html
 [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_configure-api-require.html
 [3]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html#cli-configure-role-mfa
 [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html
 [5]: https://www.yubico.com/products/services-software/download/yubico-authenticator/
 [6]: https://developers.yubico.com/yubikey-manager/
 [7]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
 [8]: https://aws.amazon.com/cli/
 [9]: https://stedolan.github.io/jq/
 [10]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
