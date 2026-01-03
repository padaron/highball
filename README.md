# Highball

A lightweight macOS menu bar app for monitoring [Railway](https://railway.com) deployments.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Glanceable Status** - Color-coded menu bar icon shows deployment health at a glance
- **Instant Notifications** - Get alerted when builds start, succeed, or fail
- **Quick Navigation** - Jump to Railway dashboard with one click
- **Deployment History** - See recent deployment activity
- **Quick Actions** - Restart or redeploy services directly from the menu bar
- **Global Shortcut** - Open Highball from anywhere with `Cmd+Shift+H`

## Installation

### Requirements
- macOS 14.0 or later
- A Railway account with an API token

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/padaron/highball.git
   cd highball
   ```

2. Open in Xcode:
   ```bash
   open Highball.xcodeproj
   ```

3. Build and run (Cmd+R)

## Setup

1. Launch Highball
2. Get an API token from [Railway Account Settings](https://railway.com/account/tokens)
3. Paste your token and select the services you want to monitor
4. Look for the status icon in your menu bar

## Status Icons

| Icon | Meaning |
|------|---------|
| Green arrow up | All services healthy |
| Purple hammer | Building |
| Blue ellipsis | Deploying |
| Red exclamation | Failed or crashed |
| Gray circle | Unknown/offline |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.
