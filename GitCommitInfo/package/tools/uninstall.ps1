param($installPath, $toolsPath, $package, $project)

# 删除 T4 模板文件
$ttFilePath = Join-Path $project.ProjectPath "GitCommitInfo.tt"
if (Test-Path $ttFilePath) {
    Remove-Item $ttFilePath
}

# 从 csproj 文件中移除添加的 ItemGroup
$csprojPath = Join-Path $project.ProjectPath $project.ProjectName + ".csproj"
$csprojContent = [System.IO.File]::ReadAllText($csprojPath)
# 假设我们要移除之前添加的 ItemGroup
$csprojContent = $csprojContent -replace "`<ItemGroup>`n    `<None Include=`"GitCommitInfo.tt`">`n      `<Generator>TextTemplatingFileGenerator`</Generator>`n      `<LastGenOutput>GitCommitInfo.cs`</LastGenOutput>`n    `</None>`n  `</ItemGroup>`n", ""
$newItemGroup = @"
    <Target Name="GetGitCommitInfo" BeforeTargets="PreBuildEvent">
        <Exec Command="git log -1 &gt; $(ProjectDir)git_commit_subject.txt" ContinueOnError="true"/>
    </Target>
    <ItemGroup>
        <EmbeddedResource Include="$(ProjectDir)git_commit_subject.txt">
            <LogicalName>Git.Commit.Subject</LogicalName>
        </EmbeddedResource>
    </ItemGroup> 
"@
$csprojContent = $csprojContent -replace $newItemGroup, ""
[System.IO.File]::WriteAllText($csprojPath, $csprojContent)