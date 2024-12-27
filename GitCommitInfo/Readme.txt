功能：编译时获取git提交信息，并写入程序集

1、添加如下内容至csproj文件
    <Target Name="GetGitCommitInfo" BeforeTargets="PreBuildEvent">
        <Exec Command="git log -1 &gt; $(ProjectDir)git_commit_subject.txt" ContinueOnError="true"/>
    </Target>
    <ItemGroup>
        <EmbeddedResource Include="$(ProjectDir)git_commit_subject.txt">
            <LogicalName>Git.Commit.Subject</LogicalName>
        </EmbeddedResource>
    </ItemGroup> 
2、复制GitCommitInfo.tt文件到项目

3、使用：
GitCommitInfo.GitInfo