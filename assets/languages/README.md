# Translations

## Adding a new language

1. Create a new folder in this folder with the language's code. Using the ISO 3166-1 codes for the language. (ex: `en` for English, `es` for Spanish, etc) (For full list of codes, see [here](https://en.wikipedia.org/wiki/ISO_3166-1#Codes))

2. Create a `config.ini` file in the folder with the following contents:

```ini
name="Your Language Name in translated language"
credits="Your Name (your github username)"
version="version based on the English config.ini version"
```

3. Copy the xml files from the `en` (English) folder and paste them in the new folder.

4. Translate the texts in the copied xml files. The {0} and {1}, and so on are placeholders are used for variables, and should be left as is.

5. Make a pull request with your changes.
Make sure the pull request is labeled as `[LANG] Add <language name>` or `[LANG] Update <language name>` or `[LANG] Fix typo in <language name>`, generally anything is allowed but it has to contain the language name.
