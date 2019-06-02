# Guide to Integrated Distributed Deploy for .net framework 4.5 (MsBuild 12) 
---

## Getting Started
---

Lets create new configurations for release, stage, debug.
In this example I will use random repository from:
https://github.com/JonPSmith/SampleMvcWebApp

From repository directories we should take preset configuration: ["Config/Preset/main.json"](Config/Preset/main.json) and put in in Config directory.

To move through process I recommend you to download tools:
Git: [Git Client](https://git-scm.com/)

Nuget: [Nuget](https://www.nuget.org/downloads)

Ms Build 12: [MsBuild12](https://www.microsoft.com/en-us/download/details.aspx?id=40760)

7 Zip: [7Zip](https://www.7-zip.org/)

If you use windows 7 upgrade your powershell version to at least 3.0: 
[Windows Management Framework 3.0](https://www.microsoft.com/en-us/download/details.aspx?id=34595)
Version you use can be check by command:
```
PS> $PSVersionTable.PSVersion
```

Execution policy unlock needed:
```
Set-ExecutionPolicy RemoteSigned
```

When all installation process is done, its time to setup main.json. Replace current content of main.json with this code:
```
{
    "AvailableVariants": [
        {
            "Release": "release.json"
        }
    ],
    "PSVersionMinimumRequired": "3",
    "MsBuildAcceptedVersions": [
        "12.0",
        "14.0",
        "15.0"
    ],
    "MsBuildVerbose": "quiet",
    "LookingForGitDirectoriesToScan": [
        "${env:ProgramFiles(x86)}",
        "${env:ProgramFiles}"
    ],
    "LookingForNugetDirectoriesToScan": [
        "C:\\"
    ],
    "LookingForMsBuildDirectoriesToScan": [
        "${env:ProgramFiles(x86)}",
        "${env:ProgramFiles}"
    ],
    "LookingFor7ZipDirectoriesToScan": [
        "${env:ProgramFiles(x86)}",
        "${env:ProgramFiles}"
    ],
    "AllPromptSelectDefaultAnswer": "false",
    "IgnoreCheckIsAdministratorMode": "false",
    "SourceDirectoryEntry": "C:\\Publish\\Environment\\Source\\{0}\\{1}",
    "PublishBackupDirectoryEntryLocal": "C:\\Publish\\Environment\\Backup\\Local",
    "PublishBackupDirectoryEntryRemote": "C:\\Publish\\Environment\\Backup\\Remote\\{0}\\{1}",
    "PublishDirectoryEntry": "C:\\Publish\\Environment\\Publish\\{0}\\{1}"
}
```

Now lets create release file:

Release.json
```
{
    "Version": "1.0.3",
    "DoRelease": "true",
    "DoBackupLocal": "false",
    "DoBackupRemote": "true",
    "AlwaysCleanStart": "false",
    "DefaultBuildConfiguration": "Release",
    "Applications": [
        {
            "Name": "SampleWebApp",
            "IsActive": "true",
            "GitRepository": "git@github.com:JonPSmith/SampleMvcWebApp.git",
            "BranchToCheckout": "master",
            "SolutionFileRelativeLocation": "",
            "Projects": [
                {
                    "Name": "SampleWebApp",
                    "IsActive": "true",
                    "PathCsProj": "SampleWebApp\\SampleWebApp.csproj",
                    "ProfileDeploy": "publishprofile",
                    "RealLocationProject": [
                        "C:\\inetpub\\wwwroot\\SampleWebApplication"
                    ]
                }
            ]
        }
    ]
}
```

Time to first run:
```
PS> .\Main.ps1 -CurrentVariant Release
```

Solving problems:

#### At Clone repository:
* Change path proper git application
* delete cached.json and set `"AllPromptSelectDefaultAnswer": "false"` and run again

Example wont work because lack of publish profile! Sample project have to have pubxml.
It might think that version 14.0, 15.0 doesn't work with publish profiles correctly - and i'll investigate why.

> TODO: prepare full process of getting started



## Known issues
---
#### git - problem with clone can't spawn ssh.exe - check other git.exe in your OS.

#### passphrase key doesn't work in non-interactive mode - if you use your openssl key with password in this scripts you might not login because we can't send password to git. Use your private key without passphrase key.


## Configurations Files

Before you would start with Main.ps1 script, you have to set variant to launch by execute command like this one: `.\Main.ps1 -CurrentVariant Debug`. List of CurrentVariants you can get from "AvailableVariants" keys.

#### Main.json - description
---
This is main file for all general configuration. All field have to be set or empty value.

* **AvailableVariants** - set your variant configuration. Here we have place for all user custom configurations. Format: "KeyName": "file-name"

* **PSVersionMinimumRequired** - minimum version that is required for your running script environment. This should prevent running script from non-tested version.

* **MsBuildAcceptedVersions** - set list of msbuild's version which will be accepted by our building process. 

* **MsBuildVerbose** - how much information should give us msbuild. From general version we have given options: 
    + Display this amount of information in the event log.
    The available verbosity levels are: q[uiet], m[inimal],
    n[ormal], d[etailed], and diag[nostic]. (Short form: /v)
    Example: /verbosity:quiet

* **LookingForGitDirectoriesToScan** - array with directories to scan for git.exe

* **LookingForNugetDirectoriesToScan** - array with directories to scan for nuget.exe

* **LookingForMsBuildDirectoriesToScan** - array with directories to scan for msbuild.exe

* **LookingFor7ZipDirectoriesToScan** - array with directories to scan for 7z.exe (7zip)

* **AllPromptSelectDefaultAnswer** - This parameter control process if there is decision to made. If this will be set to false - whenever we could find more than 1 option for tools user will be asked to select proper version. If this will be set to true - for all decision we will take first option in row. True is best option if you want to deal with this script fully automated.

* **IgnoreCheckIsAdministratorMode** - Parameter that force us to run these scripts in administrator mode. If it will be set to true then script could be running in normal mode but everywhere where administrator privileges is required script will failed. If it will be set to false the script checks if current running context is in administrator mode.

* **SourceDirectoryEntry** - directory where repositories will be downloaded, Nuget will be restoring packages and where we will start to msbuild. 
    + Placeholder {0} - version 
    + Placeholder {1} - remember to put for current variant name, you don't want to mixed debug and release compilation.

* **PublishBackupDirectoryEntryLocal** - this directory will be used to backup Build and publish processes for versions. This location is prepared for local version build and publish.

* **PublishBackupDirectoryEntryRemote** - this directory will be used to backup entire environment which will be replaced after entire publication at end of publication process. This location is prepared for remote version of files. Use with 2 placeholders. 
    + Placeholder {0} - version 
    + Placeholder {1} - remember to put for current variant name, you don't want to mixed debug and release compilation.

* **PublishDirectoryEntry** - this is temporary directory to force publication to other directory than set in csproj publication profile. Please set this because publication directory could be changed to unknown and entire publication process will fail.
    + Placeholder {0} - version 
    + Placeholder {1} - remember to put for current variant name, you don't want to mixed debug and release compilation.

#### variant.json - Description

* **Version** - specify version you are producing for entire environment. After any successful deploy you should raise version of 

* **DoRelease** - this parameter decide if we only run locally without release or we want also release. Remember when you set it to true this can potentially change production.

* **DoBackupLocal** - do/don't create backup for local publish files before release. This could be helpful if you do release a lot.

* **DoBackupRemote** - backup all remote directory which were specified in "RealLocationProject". All material will be zipped after copy to local directory specified by "PublishBackupDirectoryEntryRemote"

* **AlwaysCleanStart** - if you don't want to use cached configuration value - this will reset everything and start again. For the speed reason this isn't recommended if we did change often.

* **DefaultBuildConfiguration** - this force msbuild to use this configuration unless if project configuration specifies different value. This seams to duplicate to CurrentVariant but name of variant could be different than forced build configuration.

In this file you should put your all specific configuration to all deployed applications. When we focus on structure we can find pattern Applications => solutions => projects. 

Here look at example where we have one application: ExampleRepository with single application to build: WebApp

    "Applications": [
        {
            "Name": "SolutionName",
            "IsActive": "true",
            "GitRepository": "ssh://git@github:7999/exampleproject/examplerepository.git",
            "BranchToCheckout": "develop",
            "SolutionFileRelativeLocation": "",
            "Projects": [
                {
                    "Name": "WebApp",
                    "IsActive": "true",
                    "PathCsProj": "WebApp\\WebApp.csproj",
                    "ProfileDeploy": "DeploymentName",
                    "Configuration": "Debug"
                }
            ]
        }
    ]

Visible parameters on list are describe by:

* **Applications** - entry to applications configuration.

* Inner object in **Applications** become of fields:
    + **Name** - this will decide how we should name repository directory
    + **IsActive** - this parameter tell us to skip unused repositories
    + **GitRepository** - place where you keep your repositories (remember we use git - you have to had configured git with remote repository (private/public keys or login/pass))
    + **BranchToCheckout** - which branch will be used to work with. This branch should be corelated with destination to publish
    + **SolutionFileRelativeLocation** - you can point new location for file *.sln if it isn't in root repository directory. This is relative parameter.
        
    + **Projects** - describes every project, every iteration to build and deploy. E.g you can use different projects for every application instance:
        - **Name** - how should be called project if we want to create separate publish directory for it. Its better use case to secure unique name in every entry in entire configuration
        - **IsActive** - information about do/don't operation with this project record.
        - **PathCsProj** - path to *.csproj - This is relative parameter.
        - **ProfileDeploy** - Force msbuild to use one of deploy configuration. Not all application required the publish profile. Most console application don't have it.
        - **Configuration** - Force msbuild to compile project with configuration. You can skip this parameter because is overriding the information set up in main.json **CurrentVariant**
        - **RealLocationProject** - tell us where production files have to be deployed.

#### cached.json - Description

Cached config is used to speed up the build process. We wrote all important configuration faced during the deployment process to  the file. This can significantly increase performance. But use carefully because content of this file can trick you. If you change something e.g you changed location of Nuget you have to remove nuget record from cache file or just delete entire file cached.json. Deployment process also will cache application parameters but those information aren't consider to speed up process is rather formal information. 

