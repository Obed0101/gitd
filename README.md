<br/>
<p align="center">
  <a href="https://github.com/xXDeathAbyssXx/gitd">
    <img src="https://i.imgur.com/NxZCmoU.png" alt="Logo">
  </a>

  <h3 align="center">🚀 gitd</h3>

  <p align="center">
    Simplify Git repository downloads with ease!
    <br/>
    <br/>
    <a href="https://github.com/xXDeathAbyssXx/gitd"><strong>Explore the docs »</strong></a>
    <br/>
    <br/>
    <a href="https://github.com/xXDeathAbyssXx/gitd">View Demo</a>
    .
    <a href="https://github.com/xXDeathAbyssXx/gitd/issues">Report Bug</a>
    .
    <a href="https://github.com/xXDeathAbyssXx/gitd/issues">Request Feature</a>
  </p>
</p>

<div align="center">

![Downloads](https://img.shields.io/github/downloads/xXDeathAbyssXx/gitd/total) ![Contributors](https://img.shields.io/github/contributors/xXDeathAbyssXx/gitd?color=dark-green) ![Forks](https://img.shields.io/github/forks/xXDeathAbyssXx/gitd?style=social) ![Stargazers](https://img.shields.io/github/stars/xXDeathAbyssXx/gitd?style=social) ![Issues](https://img.shields.io/github/issues/xXDeathAbyssXx/gitd) ![License](https://img.shields.io/github/license/xXDeathAbyssXx/gitd) 

</div>

## 📚 Table Of Contents

* [About the Project](#about-the-project)
* [Features](#features)
* [Why gitd?](#why-gitd)
* [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Usage](#usage)
* [Customizing Repository Location](#customizing-repository-location)
* [Examples](#examples)
* [Contributing](#contributing)
* [Roadmap](#roadmap)
* [License](#license)
* [Creating A Pull Request](#creating-a-pull-request)
* [Authors](#authors)

## 🚀 About The Project 

![Screen Shot](images/screenshot.png)

This project provides a simple Zsh script (`gitd`) to streamline the process of downloading Git repositories. It offers a user-friendly command-line interface to quickly clone repositories with customizable settings.

## ✨ Features 

- 🔄 **Easy Cloning:** Quickly clone Git repositories with just a few commands.
- 📁 **Customizable Base Directory:** Choose your preferred base directory for downloaded repositories.
- 🎨 **Stylish Logs:** Colorful and informative logs for a better user experience.
- ⚙️ **Configuration Options:** Customize the script behavior using environment variables.

## 🤔 Why gitd? 

- **Simplicity:** gitd is designed to be straightforward and easy to use.
- **Style:** Enjoy stylish and colorful logs during the cloning process.
- **Configurability:** Tailor gitd to your preferences with customizable options.

## 🛠️ Built With 

* Zsh (Z shell)

## 🚀 Getting Started 

To get started with `gitd`, follow the instructions below.

### 📋 Prerequisites 

* GitHub CLI (`gh`) for retrieving repository details

### 🛠️ Installation 

1. Download the `gitd` script.

2. Move the script to a directory in your shell's PATH. For example, you can move it to `~/bin` or `/usr/local/bin`:

```bash
mv gitd /usr/local/bin
```

3. Give execute permissions to the script:

```sh
chmod +x /usr/local/bin/gitd
```

Uninstalling?

## 🛠️ Usage 

Use the gitd script with the following syntax:

```sh
gitd <repo_url> [branch]
```

Replace <repo_url> with the URL of the Git repository you want to download. Optionally, you can specify a branch.

## Customizing Repository Location 🌐

By default, gitd saves repositories in the $HOME/Repos directory. You can customize this location by setting the GITD_BASE_DIR environment variable. For example:

```sh
export GITD_BASE_DIR=~/my_repos
```

Add this line to your shell configuration file (e.g., .zshrc or .bashrc) to make it persistent across sessions.

## 🚀 Examples 

- Clone a repository with the default settings: `gitd https://github.com/xXDeathAbyssXx/gitd`
- Customize the base directory: `export GITD_BASE_DIR=~/Downloads`

## 🗺️ Roadmap 

See the [open issues](https://github.com/xXDeathAbyssXx/gitd/issues) for a list of proposed features (and known issues).

## 🤝 Contributing 

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.
* If you have suggestions for adding or removing projects, feel free to [open an issue](https://github.com/xXDeathAbyssXx/gitd/issues/new) to discuss it, or directly create a pull request after you edit the *README.md* file with necessary changes.
* Please make sure you check your spelling and grammar.
* Create individual PR for each suggestion.
* Please also read through the [Code Of Conduct](https://github.com/xXDeathAbyssXx/gitd/blob/main/CODE_OF_CONDUCT.md) before posting your first idea as well.

### 🌐 Creating A Pull Request 

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License 

Distributed under the Apache License. See [LICENSE](https://github.com/xXDeathAbyssXx/gitd/blob/main/LICENSE.md) for more information.

## 🌟 Authors 

* **DeathAbyss** - *Fullstack Developer* - [DeathAbyss](https://github.com/xXDeathAbyssXx) - *Built gitd*