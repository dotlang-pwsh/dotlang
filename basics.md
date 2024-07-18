# 😁 Basics

Of course, every language starts with the basics.

The first thing you have to do is create a new project, to do so:

### Creating your first project.

1- Make a folder anywhere after installing dotlang

2- Open the terminal in that folder you have created

3- type in: `dot new` and output should be:

![image](https://github.com/neoapps-dev/dotlang/assets/158327205/8e2e5336-b7cf-4990-9104-21731815f514)

4- now open `main.dot` in any of your favourite code editors (e.g. VS Code, Notepad++, etc.)

5- you're gonna see the first line `Import-Module .\dot.ps1`, do NOT touch it, this will import dotlang.

6- you're now ready to learn the basics!!

## Basic Commands

...

### Print Text

To print a text on the screen simply,

```powershell
printTxt("Hi I'm dotlang!"); # semicolons are optional.
```

### Print Warning

To print a warning text (yellow and followed by the word WARNING:) simply,

```powershell
printWarning("This is a test!"); # Output: WARNING: This is a test!
```

### Print Errors,

ever thought of showing an error to the user? well you can! simply,

```powershell
printError("This is just a test!");
```

Output: ![image](https://github.com/neoapps-dev/dotlang/assets/158327205/4e037a65-4f31-4c4d-9a38-3b4ff79202d6)

### Print Colored Text

yeah! text with your own custom color! simply,

```powershell
printColored "I'm green!" "Green";
```

Output: ![image](https://github.com/neoapps-dev/dotlang/assets/158327205/14cc4707-db18-4b7f-83d7-5feac8b2e565)

### Print Progress

your code takes time to execute? no worries just simply use,

```powershell
printProgress "Activity" "Status";
```

Output: ![image](https://github.com/neoapps-dev/dotlang/assets/158327205/432ddf25-d2c7-4ccf-a61a-b70a2ed33de4)

That's it for basic commands!
