---
title: Making life easier with Yubikeys for browser TOTP
author: sigmaris
type: post
date: 2020-01-25T13:49:00+00:00
url: /2020/01/yubikey-browser/
categories:
  - mac
---
Following on from the post about AWS logins with Yubikey, I also wanted to share another helpful bit of code to automate typing [TOTP codes][1] from a Yubikey into web pages on macOS.

The usefulness of this is hopefully on the decline as websites migrate to [WebAuthentication][2] - which interfaces directly with a token like a Yubikey instead of requiring a code input as text, and doesn't require this approach - but TOTP codes are still used by many sites at the time of writing.

This approach is specific to macOS as it relies on application scripting with AppleScript. The idea is to have a shell script which can use AppleScript to:

1. Get the URL of the currently open tab from the currently focused web browser.
1. Identify which TOTP code to use for the URL, or prompt for which one to use.
1. Retrieve the current TOTP code from the Yubikey, prompting for a touch if necessary.
1. Simulate typing the TOTP code into the currently focused web browser.

and then trigger that AppleScript from a hotkey using Automator. Then you can click on a text input field for the TOTP code on a web page, insert a Yubikey, press the hotkey and the correct TOTP code gets entered into the text input field.

## Prerequisites

This approach uses the packages [`ykman`][3] (Yubikey Manager) to interact with the Yubikey, and [`choose-gui`][4] to show a graphical prompt for choosing the OATH account on the Yubikey to use, if the current URL isn't recognised. Both of these can be installed from [Homebrew][5]: `brew install ykman choose-gui`.

## The Shell Script

Using a text editor, save this script to e.g. `~/bin/ykoath.sh` and make it executable (`chmod +x ~/bin/ykoath.sh`):

```shell
#!/bin/bash

# Requires Homebrew packages ykman and choose-gui
# The path where Homebrew installs packages on ARM and Intel macOS differs, so check for both locations:
if [[ -x /opt/homebrew/bin/ykman ]]
then
	YKMAN_PATH=/opt/homebrew/bin/ykman
else
	YKMAN_PATH=/usr/local/bin/ykman
fi
if [[ -x /opt/homebrew/bin/choose ]]
then
	CHOOSE_PATH=/opt/homebrew/bin/choose
else
	CHOOSE_PATH=/usr/local/bin/choose
fi

# Applescript snippet to guess the TOTP account name from the current tab URL:
TOTP_NAME=$(osascript <<'EOS'
on getCurrentTabUrl()
	tell application "System Events" to set frontApp to name of first process whose frontmost is true
	
	if (frontApp = "Safari") or (frontApp = "Webkit") or (frontApp = "Safari Technology Preview") then
		using terms from application "Safari"
			tell application frontApp to set currentTabUrl to URL of front document
		end using terms from
	else if (frontApp = "Google Chrome") or (frontApp = "Google Chrome Canary") or (frontApp = "Chromium") then
		using terms from application "Google Chrome"
			tell application frontApp to set currentTabUrl to URL of active tab of front window
		end using terms from
	else
		set currentTabUrl to "UNKNOWN"
	end if
	return currentTabUrl
end getCurrentTabUrl

on splitText(theText, theDelimiter)
	set AppleScript's text item delimiters to theDelimiter
	set theTextItems to every text item of theText
	set AppleScript's text item delimiters to ""
	return theTextItems
end splitText

on run
	set currentTabUrl to getCurrentTabUrl()
	if currentTabUrl is equal to "UNKNOWN" then
		return "UNKNOWN"
	end if
	set urlComponents to splitText(currentTabUrl, "/")
	set hostComponents to splitText(third item of urlComponents, ".")
	
	if hostComponents ends with {"signin", "aws", "amazon", "com"} then
		set totpName to "Amazon Web Services:your-user@your-aws-account"
	else if currentTabUrl starts with "https://app.netlify.com/two-factor-auth/" then
		set totpName to "Netlify:your-account@your-domain"
	else
		set totpName to "UNKNOWN"
	end if
	
	return totpName
end run
EOS
)

if [[ $? -ne 0 || -z "$TOTP_NAME" ]]
then
	osascript -e "display alert \"Error getting TOTP name: ${TOTP_NAME//\"}\""
	exit 1
fi

# If the TOTP account name can't be guessed, use choose-gui to prompt for it:
if [[ "${TOTP_NAME}" == "UNKNOWN" ]]
then
	TOTP_NAME="$($YKMAN_PATH oath accounts list | $CHOOSE_PATH 2>&1)"
fi

if [[ -z "$TOTP_NAME" ]]
then
	# Assume the user pressed Esc to close the choose window without selecting anything
	osascript -e "display notification \"No TOTP account chosen\" with title \"ykoath.sh\""
	exit 0
fi

# The ykman CLI may prompt for a touch before emitting the TOTP code;
# since this runs in the background we need to convert the CLI prompt to a popup notification:
read_stderr() {
	while read line
	do
		# Display a macOS notification popup with each line of stderr (where it prompts for a touch)
		osascript -e "display notification \"${line//\"}\" with title \"ykman\" subtitle \"${TOTP_NAME//\"}\""
	done
}

# Request the code from the Yubikey:
TOTP_CODE=$( $YKMAN_PATH oath accounts code -s "$TOTP_NAME" 2> >(read_stderr) )

if [[ $? -ne 0 ]]
then
	osascript -e "display alert \"Error getting TOTP value for ${TOTP_NAME//\"}: ${TOTP_CODE//\"}\""
	exit 1
fi

# Simulate typing in the code using Applescript
osascript -e "on run argv" \
		  -e "tell application \"System Events\" to keystroke item 1 of argv" \
		  -e "end run" \
		  "$TOTP_CODE"
```

There's unfortunately no support for Firefox here as it doesn't seem to implement application scripting functionality on macOS, but Safari and Google Chrome are supported.

You can edit the `else if currentTabUrl starts with ...` series of conditions and add more URL-matching conditions matching the specific sites, and OATH account names, you want to use this with. Make sure the `totpName`s used for each site are identical to the corresponding names in the output of `ykman oath accounts list`.

## Setting up the Trigger

The Automator app in macOS can be used to set up a global keyboard hotkey for running this script. In Automator, create a new Quick Action and set it to receive "no input" in "any application". Add a "Run Shell Script" action, and enter this in the script, assuming your main shell script from above is saved at `~/bin/ykoath.sh`:

```shell
~/bin/ykoath.sh
```

Save the Automator workflow, then go to System Settings (or Preferences in older macOS) > Keyboard > Shortcuts. Select Services from the sidebar and find your service. Add a keyboard shortcut by double clicking (none) on the right, and typing in your shortcut - I like to use one of the F13-F19 keys on the full-size Apple Keyboard.

In theory you could also just copy the whole shell script into the Automator action, though I prefer to have the script saved on disk as I can then keep it in a Git repository and sync that to more than one Mac.

## Usage

On a web page which expects you to type a TOTP code, just click on the TOTP text input field to give it focus, and then press the hotkey you've assigned to run the script. The correct TOTP code should be typed into the text input field.

The first time you run this in an app, macOS will prompt you to allow the app control of the system via accessibility features - this is because the Automator workflow and script runs in the context of the active app where the workflow is triggered, and it uses System Events to simulate typing, which triggers this prompt from macOS. Allow the permission in System Settings, and it should work without prompting in future.

[1]: https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm
[2]: https://webauthn.guide/
[3]: https://developers.yubico.com/yubikey-manager/
[4]: https://github.com/chipsenkbeil/choose
[5]: https://brew.sh/
