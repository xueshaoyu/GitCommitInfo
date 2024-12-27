param($installPath, $toolsPath, $package, $project)

# 生成 T4 模板文件
$ttFilePath = Join-Path $project.ProjectPath "GitCommitInfo.tt"
@"
<#@ template language="C#" #>
<#@ assembly name="System.Core" #>
<#@ import namespace="System.Linq" #>
<#@ import namespace="System.Text" #>
<#@ import namespace="System.Collections.Generic" #>
<#@ template debug="false" hostspecific="false" language="C#" #>
<#@ output extension=".cs" #>
<#@ import namespace="System.IO" #>
namespace GitCommitInfo
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Reflection;

    public class GitInfo
    {
        public string CommitHash{ get;set; }
        public string CommitAuthor{ get;set; }
        public DateTime CommitDate{ get;set; } = DateTime.MinValue;
    }

    public static class GitCommitInfo
    { 
        static GitCommitInfo()
        {
            try
            {   using (var subjectStream = Assembly.GetExecutingAssembly().GetManifestResourceStream("Git.Commit.Subject"))
                {
                    var text = new List<string>();
                    using (var reader = new StreamReader(subjectStream))
                    {
                        string line;
                        var count = 0;
                        while ((line = reader.ReadLine()) != null)
                        {
                            text.Add(line);
                            count++;
                            if (count > 3)
                            {
                                break;
                            }
                        }
                    } 
                    if (text.Count >= 3)
                    {                  
                        gitInfo.CommitHash = text[0].Replace("commit", "").Trim();
                        gitInfo.CommitAuthor = text[1].Replace("Author:", "").Trim();
                        if(DateTime.TryParse(text[2].Replace("Date:", "").Trim(),out var date))
                        {
                            gitInfo.CommitDate = date;
                        }
                    }
                }
            }
            catch
            { 
            }
        }

        public static GitInfo gitInfo = new GitInfo();
        public static GitInfo GitInfo
        {
            get
            {              
                return gitInfo;
            }
        }      
    }
}
"@ | Out-File -FilePath $ttFilePath

# 修改 csproj 文件
$csprojPath = Join-Path $project.ProjectPath $project.ProjectName+".csproj"
$csprojContent = [System.IO.File]::ReadAllText($csprojPath)
# 假设我们要添加一个新的 ItemGroup
$newItemGroup = @"
     <ItemGroup>
        <None Include="GitCommitInfo.tt">
          <Generator>TextTemplatingFileGenerator</Generator>
          <LastGenOutput>GitCommitInfo.cs</LastGenOutput>
        </None>
    </ItemGroup>
    <Target Name="GetGitCommitInfo" BeforeTargets="PreBuildEvent">
        <Exec Command="git log -1 &gt; $(ProjectDir)git_commit_subject.txt" ContinueOnError="true"/>
    </Target>
    <ItemGroup>
        <EmbeddedResource Include="$(ProjectDir)git_commit_subject.txt">
            <LogicalName>Git.Commit.Subject</LogicalName>
        </EmbeddedResource>
    </ItemGroup> 
"@ | Out-File -FilePath $ttFilePath -Encoding UTF8
$csprojContent = $csprojContent -replace "</Project>", "$newItemGroup`n</Project>"
[System.IO.File]::WriteAllText($csprojPath, $csprojContent)