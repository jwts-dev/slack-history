# slack-history

Export Slack Channel Files and update Slack JSON for use with slack2html

# Usage

## 1. Download workspace data

1. [Export your workspace data](https://slack.com/help/articles/201658943-Export-your-workspace-data) from Slack. This involves using the Slack GUI to (a) initiate the export process, then (b) click a link to download a ZIP file containing your workspace data.
1. Extract the contents of the ZIP file into an empty folder on your computer (e.g. `C:\Temp\slack\exported-data`).

## 2. Download the PowerShell script

1. Launch PowerShell.
1. Clone this repository onto your computer.
    ```powershell
    PS> git clone https://github.com/jwts-dev/slack-history.git
    ```
    > Note: In case you don't have Git installed, you can, instead, [download the contents of the main branch of the repository](https://github.com/jwts-dev/slack-history/archive/refs/heads/main.zip) as a ZIP file, then extract its contents.
1. Navigate into the root folder of the repository.
    ```powershell
    PS> cd .\slack-history\
    ```

## 3. Edit the PowerShell script

1. Open the script file (i.e. `Slack_Export_Channel_Files.ps1`) in a text editor.
1. Edit the value of the `$ExportPath` variable (currently defined on line 1) to contain the path to the root folder of the data you exported from Slack earlier.
    ```diff
    - $ExportPath = ".\slackHistory"
    + $ExportPath = "C:\Temp\slack\exported-data"
    ```
    > Note: If you don't edit the value, the script will look for exported Slack data in the following folder: `.\slackHistory`
1. Edit the following line of code (currently line 19) as shown below.
    ```diff
    - $channelList = Get-Content -Raw -Path .\slackHistory\channels.json | ConvertFrom-Json
    + $channelList = Get-Content -Raw -Path "$ExportPath\channels.json" | ConvertFrom-Json
    ```
    > Note: If you don't edit the line, the script will look for the exported Slack channel list in the following folder: `.\slackHistory`
    >
    > Note: This change may eventually be incorporated into the authoritative script, rendering this manual step unnecessary. For now, though, it is necessary.
1. Save the changes to the file.

## 4. Run the PowerShell script

1. Run the script (in a way that [bypasses](https:/go.microsoft.com/fwlink/?LinkID=135170) PowerShell's execution policy).
    ```powershell
    PS> PowerShell.exe -ExecutionPolicy Bypass -File .\Slack_Export_Channel_Files.ps1
    ```

When the script finishes running, it will print a message that says "`Exiting`" and the PowerShell prompt will reappear.

# References

1. https://docs.microsoft.com/en-us/microsoftteams/migrate-slack-to-teams#channel-files