# NiceUtil

## The idea

NiceUtil combines the visual aspect of applications like Spaceman, Waybar etc, to show spaces in your menubar, and applications that let you save your Workspaces/Virtual Desktops.

## Usage

1. Have a mac
2. Disable space switching to open occurrence of an application:
![Screenshot 4](https://github.com/user-attachments/assets/6293d143-b9e8-4392-bde3-2d935f626eea)

3. Clone the repo to your computer and use Xcode to build it into an Application.
4. Run the application and go to a clean desktop or stay on the current one.

![Screenshot 1](https://github.com/user-attachments/assets/1f18566a-7ed4-4d67-92da-e3c7516bcad4)

5. Make sure apps that you want to save are running on the desktop and from the menu click "Save Current Workspace...".

![Screenshot 2](https://github.com/user-attachments/assets/4c2a3361-ce37-4b11-a4e4-88f26e7b09f5)

6. Name the space and in the future when you load it, it starts up all of the applications that were saved.
   
![Screenshot 3](https://github.com/user-attachments/assets/749f683c-9b9f-4804-b53a-507da252c5ac)

> [!WARNING] Could use help on
>
> Right now it opens a new instance of the application, eg you load a space with Safari, you'll have 2 Safaris in the dock.
> I'm pretty sure causing this is the API that I'm using. If anyone has any alternatives or solutions, help is welcome.
>

> [!IMPORTANT] Acknowledgements
>
> This project uses open source software under the MIT License:
>
> - Logic for the indicator - [Sasindu Jayasinghe - Spaceman](https://github.com/Jaysce/Spaceman), an open-sourcean application for macOS that allows you to view your Spaces / Virtual Desktops in the menu bar.
> - Package for the shortcuts [Sindre Sorhus - KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts?tab=readme-ov-file), Custom global keyboard shortcuts for your macOS app
