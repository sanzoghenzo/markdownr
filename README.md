# markdownr

Android app that converts an URL to markdown, and lets you share it to your favorite notes app.

I've written this app to save articles I found interesting to a note taking app that uses markdown and git to sync notes to my pc.

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/com.sanzoghenzo.markdownr/)

## Features

- Downloads the web page specified in the URL input field, cleans it up (like readability does) and converts it to Markdown.
- Ability to enable/disable parts of the markdown:
  - YAML front matter with the creation date, the source url and the author
  - The "Clipped from <url>" text under the title
  - The excerpt of the article
  - The article body
- Ability to show the markdown preview
- Share the markdown to other apps with standard share intent.
- The URL can be also be shared from another app (for example the web browser);
  markdownr will automatically convert it and show the share intent.
- If something isn't working with the share button, you can use the copy button to send the text to the clipboard.

## Developer info

This started as a super simple app made in flutter, with only a single module.

It takes advantage of a few wonderful libraries:

- `http`
- `html2md`
- `intl`
- `share_plus`
- `receive_sharing_intent`
- `fluttertoast`
- `shared_preferences`
- `flutter_charset_detector`
- `charset_converter`
- `flutter_markdown`

I just glued them up in a day, learning some Flutter in the meantime.

In another day or so, I added `readability4J` kotlin package to the mix to cleanup the HTML before converting it to markdown.
