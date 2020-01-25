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

This approach is specific to macOS as it relies on application scripting with AppleScript. The idea is to have an AppleScript which can:

1. Get the URL of the currently open tab from the currently focused web browser.
1. Identify which TOTP code to use for the URL.
1. Retrieve the current TOTP code from the Yubikey.
1. Simulate typing the TOTP code into the currently focused web browser.

and then trigger that AppleScript from a hotkey using e.g. [Quicksilver][3]. Then you can click on a text input field for the TOTP code on a web page, insert a Yubikey, press the hotkey and the correct TOTP code gets entered into the text input field.

## The AppleScript

Using the Script Editor app, save this script to e.g. `~/Library/Scripts/PasteTOTP.scpt`.

```applescript
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
    display alert "Unsupported app " & frontApp & "."
    return
end if

if currentTabUrl starts with "https://www.dropbox.com/" then
    set totpName to "Dropbox"
else if currentTabUrl starts with "https://github.com/sessions/two-factor" then
    set totpName to "Github"
else if currentTabUrl starts with "https://dns.he.net/" or currentTabUrl starts with "https://tunnelbroker.net/" or currentTabUrl starts with "https://www.tunnelbroker.net/" then
    set totpName to "Hurricane Electric"
else if currentTabUrl starts with "https://www.paypal.com/" then
    set totpName to "PayPal"
else
    display alert "Unrecognised URL " & currentTabUrl & "."
    return
end if

set totpCode to do shell script "LANG=en_GB.UTF-8 /usr/local/bin/ykman oath code " & quoted form of totpName & " 2>/dev/null | sed -E 's/.*" & totpName & "[[:space:]]+([[:digit:]]+)/\\1/'"

if not totpCode = "" then
    tell application "System Events"
        keystroke totpCode
    end tell
else
    display alert "No response from Yubikey. " & totpCode
end if
```

There's unfortunately no support for Firefox here as it doesn't seem to implement application scripting functionality on macOS, but Safari and Google Chrome are supported.

You can add more URL-matching conditions into the `else if currentTabUrl starts with ...` series of conditions depending on the specific sites you want to use this with. Make sure the `totpName`s used for each site are identical to the corresponding names in the output of `ykman oath code`.

## Setting up the Trigger

Any utility which can run an AppleScript on a hotkey could probably be used for this - I use [Quicksilver][3]. In the Quicksilver Preferences, add a Custom Keyboard Trigger, select your script as the Item, and use Run Script as the Action. Your script should be found by Quicksilver in the **Catalog -> Scripts -> User** section if it's saved in `~/Library/Scripts/` - you might need to rescan the catalog after saving the script for the first time. Configure the trigger to use the hotkey you want - I use one of the extra function keys on the Apple Wired Keyboard.

![Example showing a custom trigger for this AppleScript in Quicksilver](/blog/uploads/2020/01/quicksilver_totp.png)

## Usage

On a web page which expects you to type a TOTP code, just click on the TOTP text input field to give it focus, and then press the hotkey you've assigned to run the script. The correct TOTP code should be typed into the text input field.

[1]: https://en.wikipedia.org/wiki/Time-based_One-time_Password_algorithm
[2]: https://webauthn.guide/
[3]: https://qsapp.com
