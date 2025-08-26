# Mello PowerShell Profile (🚧 Under Construction 🚧)

<p align="center" style="color:#9DC183; font-size:1.5em;"><strong><em>Stay mellow. Keep moving.</em></strong></p>

A custom PowerShell profile with some additional functionality:

* Cures that rash
* Eliminates girlfriends
* Get rid of that silly 'dignity' you've been stuck with

## Requirements

1. PowerShell 5.x or 7.x
1. Windows 10 or later

## Installation

1. Run the following command in a PowerShell window (elevation is not necessary) and it will install the custom profile:

```pwsh
# Short version with the default aliases in place
irm 'https://github.com/voltaire-toledo/mizu-ps-profile/raw/main/install-profile.ps1' | iex

# Long version
Invoke-RestMethod 'https://github.com/voltaire-toledo/mizu-ps-profile/raw/main/install-profile.ps1' | Invoke-Expression
```

1. You will be prompted to select which profile to modify. The default is to your own profile in the **CurrentUserCurrentHost** one.
1. You can choose to back up your existing profile if you want.

## Troubleshooting

## Resources

* [Customizing your shell environment (PowerShell 7.5)]([url](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/creating-profiles?view=powershell-7.5))

## To-Do

* [ ] Display Keybindings
* [ ] Custom aliases for Terraform (tf, tfi, tfimport, tfp tfa, tfd)
* [ ] Custom aliases for Get-ChildItem (ll, la, lla)
* [ ] Show 'Elevated' banner when running shell in privileged mode
* Import the following Modules
  * [ ] ARM Test Toolkit
  * [ ] Terminal-Icons
* [ ] Azure CLI Argument completer
* [ ] Get-My-IP (Get your gateway's public IP address)
* [ ] Override 24H2's sudo (sudo --preserve-env --inline)
* [ ] Get-Uptime
* [ ] Function for grep (Select-String -Pattern [0])
* [ ] Set-Alias for df (Get-Volume)
* [ ] Customize oh-my-posh theme
