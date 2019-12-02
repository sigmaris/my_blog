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

Although the AWS CLI supports MFA authentication to temporarily [assume roles][3], it doesn't currently support using MFA authentication with IAM user credentials. Also, it requires you to look up a code (e.g. from an authenticator app on your phone) and type it in to the terminal each time. With the YubiKey's support for RFC 6238 TOTP tokens (the same type of time-based one-time token that AWS uses) we can make this a much smoother process by adding some functions to our shell startup file. This guide applies to Bash and Bash-compatible shells like zsh, on Mac OS and Linux.

## Step 1: Store the MFA secret key on your YubiKey

There are a couple of ways to store the MFA secret key on your YubiKey. First you need to [set up a Virtual MFA device][4] on your IAM user account. When you get to the stage where the secret key is displayed in a QR code, you need to get this onto the YubiKey. You can use the "Scan QR code" option in the [Yubico Authenticator][5] desktop app, or you can install the `ykman` [CLI tool][6] for YubiKey, use the "Show secret key" option on AWS and then use the CLI command `ykman oath add AWS` to add the secret key. You'll need the `ykman` tool for the next step anyway.

## Step 2: Install the YubiKey Manager and AWS CLI tools

Make sure the [YubiKey Manager CLI tool][6] is installed and on your `$PATH` so that you can enter the command `ykman` in a terminal and it'll run. Similarly, make sure the [AWS CLI tool][7] is installed and you can run the `aws` command.

With `ykman` installed and your YubiKey inserted, you should be able to run `ykman oath code` at the terminal, and see your 6-digit MFA code for AWS listed as:

    ...    111111
    AWS    123456
    ...    222222

The rest of this guide assumes you've named it "AWS" as above on the YubiKey.

## Step 3: Save your personal AWS access keys on disk for the AWS CLI

In order to call the AWS APIs to obtain MFA-authenticated session credentials, we need to first authenticate somehow to AWS. The way to do this is to use AWS access keys, and to provide these to the AWS CLI, we need to save them to the `~/.aws/credentials` file. Run the command `aws configure`, which will prompt for your AWS Access Key ID, Secret Access Key and a few other defaults, and save them in your `~/.aws` directory.

## Step 4: test getting MFA-authenticated session credentials

...

## Step 5: Add function definitions to your shell startup file

 [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html "Using Multi-Factor Authentication (MFA) in AWS"
 [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_configure-api-require.html "Configuring MFA-Protected API Access"
 [3]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html#cli-configure-role-mfa
 [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html
 [5]: https://www.yubico.com/products/services-software/download/yubico-authenticator/
 [6]: https://developers.yubico.com/yubikey-manager/
 [7]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
