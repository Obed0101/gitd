<br/>
<p align="center">
  <a href="https://github.com/Obed0101/gitd">
    <img src="https://i.imgur.com/NxZCmoU.png" alt="Logo">
  </a>

  <h3 align="center">🚀 gitd</h3>

  <p align="center">
    Simplify Git repository downloads with ease!
    <br/>
    <a href="https://github.com/Obed0101/gitd/issues">Report Bug</a>
    .
    <a href="https://github.com/Obed0101/gitd/issues">Request Feature</a>
  </p>
</p>

<div align="center">

![Downloads](https://img.shields.io/github/downloads/Obed0101/gitd/total) ![Contributors](https://img.shields.io/github/contributors/Obed0101/gitd?color=dark-green) ![Forks](https://img.shields.io/github/forks/Obed0101/gitd?style=social) ![Stargazers](https://img.shields.io/github/stars/Obed0101/gitd?style=social) ![Issues](https://img.shields.io/github/issues/Obed0101/gitd) ![License](https://img.shields.io/github/license/Obed0101/gitd)

</div>

## 📚 Table Of Contents

- [About the Project](#🚀-about-the-project)
- [Features](#✨-features)
- [Why gitd?](#🤔-why-gitd)
- [Built With](#🛠️-built-with)
- [Getting Started](#🚀-getting-started)
  - [Prerequisites](#📋-prerequisites)
  - [Installation](#🛠️-installation)
- [Usage](#🛠️-usage)
  - [Options](#⚙️-options)
- [Customizing Repository Location](#🌐-customizing-repository-location)
- [Examples](#🚀-examples)
- [Roadmap](#🗺️-roadmap)
- [Contributing](#🤝-contributing)
  - [Creating A Pull Request](#🌐-creating-a-pull-request)
- [License](#📄-license)
- [Authors](#🌟-authors)

## 🚀 About The Project

This project provides a simple Zsh script (`gitd`) to streamline the process of downloading Git repositories. It offers a user-friendly command-line interface to quickly clone repositories with customizable settings.

## ✨ Features

- 🔄 **Easy Cloning:** Quickly clone Git repositories with just a few commands.
- 📁 **Customizable Base Directory:** Choose your preferred base directory for downloaded repositories.
- 🎨 **Stylish Logs:** Colorful and informative logs for a better user experience.
- ⚙️ **Configuration Options:** Customize the script behavior using environment variables.
- ⚙️ **Setup Option:** Set up the downloaded repository, including installing dependencies.

## 🤔 Why gitd?

- **Simplicity:** gitd is designed to be straightforward and easy to use.
- **Style:** Enjoy stylish and colorful logs during the cloning process.
- **Configurability:** Tailor gitd to your preferences with customizable options.

## 🛠️ Built With

- Zsh (Z shell)

## 🚀 Getting Started

To get started with `gitd`, follow the instructions below.

### 📋 Prerequisites

- Zsh or Bash installed on your system
- GitHub CLI (`gh`) for retrieving repository details

### 🛠️ Installation

You can install `gitd` by running the following command in your terminal:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Obed0101/gitd/main/install.sh)"
```

## 🛠️ Usage

Use the gitd script with the following syntax:

```sh
gitd [options] <repo_url> [options]
```

Replace <repo_url> with the URL of the Git repository you want to download. Optionally, you can specify a branch.

### ⚙️ Options:

| Option          | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `-h, --help`    | Show help message.                                                   |
| `-v, --version` | Display the script version.                                          |
| `-s, --setup`   | Set up the downloaded repository, including installing dependencies. |
| `-b, --branch`  | Specify the branch for cloning.                                      |

> **Note:** The setup option is currently compatible with the following package managers and systems:

- **npm:** Node.js package manager
- **yarn:** Fast, reliable, and secure dependency management
- **pnpm:** Fast, disk space efficient package manager
- **bundle:** Ruby dependency manager
- **mvn:** Apache Maven for Java projects
- **go:** Go programming language
- **gcc:** GNU Compiler Collection (for C/C++ projects)

## 🌐 Customizing Repository Location

By default, gitd saves repositories in the $HOME/Repos directory. You can customize this location by setting the GITD_BASE_DIR environment variable. For example:

```sh
export GITD_BASE_DIR=~/my_repos
```

Add this line to your shell configuration file (e.g., .zshrc or .bashrc) to make it persistent across sessions.

## 🚀 Examples

- Clone a repository with the default settings: `gitd https://github.com/Obed0101/gitd`
- Specify a branch for cloning: `gitd -b main https://github.com/Obed0101/gitd`
- Set up a repository after cloning: `gitd -s https://github.com/example/repo`
- Customize the base directory: `export GITD_BASE_DIR=~/Downloads`

## 🗺️ Roadmap

See the [open issues](https://github.com/Obed0101/gitd/issues) for a list of proposed features (and known issues).

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

- If you have suggestions for adding or removing projects, feel free to [open an issue](https://github.com/Obed0101/gitd/issues/new) to discuss it, or directly create a pull request after you edit the _README.md_ file with necessary changes.
- Please make sure you check your spelling and grammar.
- Create individual PR for each suggestion.
- Please also read through the [Code Of Conduct](https://github.com/Obed0101/gitd/blob/main/CODE_OF_CONDUCT.md) before posting your first idea as well.

### 🌐 Creating A Pull Request

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the Apache License. See [LICENSE](https://github.com/Obed0101/gitd/blob/main/LICENSE) for more information.

## 🌟 Authors

- **Obed0101** - _Fullstack Developer_ - [Obed0101](https://github.com/Obed0101) - _Built gitd_
- **AlphaTechnolog** - _Fullstack Developer_ - [AlphaTechnolog](https://github.com/AlphaTechnolog) - _Developer/Tester of gitd_
