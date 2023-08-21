# Markdownr

Convert web pages to markdown and integrate seamlessly with Obsidian.

Original app by sanzoghenzo. Fork by [@IAmStoxe](https://github.com/IAmStoxe).

## Description

Markdownr is a Flutter application that allows users to:

- Convert web pages to markdown format.
- Share the markdown content or copy it to the clipboard.
- Integrate with the Obsidian note-taking application through advanced URI schemes.

## Screenshot

![Screenshot](./metadata/en-US/images/markdownr.png)

## Features

1. **URL to Markdown Conversion:** Easily convert any web page to a markdown formatted text.
2. **Seamless Sharing:** Instantly share the converted markdown with other applications or save it to the clipboard.
3. **Obsidian Integration:** Directly send the markdown content to the Obsidian app with a single tap.
4. **Customizable Settings:** Configure how you want to send content to Obsidian, such as specifying the vault name, filepath, and more.
5. **Persistent Settings:** The app remembers your last-used settings for a hassle-free experience.

## Installation

To install Markdownr, you will need a Flutter development environment set up on your machine.

1. Clone the repository:

   ```sh
   git clone https://github.com/IAmStoxe/Markdownr.git
   ```

2. Navigate to the cloned directory:

   ```sh
   cd Markdownr
   ```

3. Install the dependencies:

   ```sh
   flutter pub get
   ```

4. Run the app:

   ```sh
   flutter run
   ```

## Usage

1. **Main Screen:**

   - Enter the URL you want to convert.
   - Use the "CONVERT" button to get the markdown representation.
   - Share, copy or send the markdown to Obsidian using the provided buttons.
   - Adjust settings using the gear icon on the top right.

2. **Obsidian Settings Screen:**
   - Modify your Obsidian integration settings.
   - Specify vault name, mode (new, write, overwrite, etc.), and filepath.
   - Choose whether to use the daily note feature and specify a heading if needed.
   - Save the settings using the save icon on the top right.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is open-source. Please ensure to give credit to the original author sanzoghenzo and the maintainer @IAmStoxe.
