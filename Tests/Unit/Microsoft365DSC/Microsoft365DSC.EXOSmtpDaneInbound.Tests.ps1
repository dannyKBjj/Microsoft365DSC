[CmdletBinding()]
param(
)
$M365DSCTestFolder = Join-Path -Path $PSScriptRoot `
                        -ChildPath '..\..\Unit' `
                        -Resolve
$CmdletModule = (Join-Path -Path $M365DSCTestFolder `
            -ChildPath '\Stubs\Microsoft365.psm1' `
            -Resolve)
$GenericStubPath = (Join-Path -Path $M365DSCTestFolder `
    -ChildPath '\Stubs\Generic.psm1' `
    -Resolve)
Import-Module -Name (Join-Path -Path $M365DSCTestFolder `
        -ChildPath '\UnitTestHelper.psm1' `
        -Resolve)

$Global:DscHelper = New-M365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "EXOSmtpDaneInbound" -GenericStubModule $GenericStubPath
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope
        BeforeAll {

            $secpasswd = ConvertTo-SecureString (New-Guid | Out-String) -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ('tenantadmin@mydomain.com', $secpasswd)

            Mock -CommandName Confirm-M365DSCDependencies -MockWith {
            }

            Mock -CommandName Get-MSCloudLoginConnectionProfile -MockWith {
            }

            Mock -CommandName New-M365DSCConnection -MockWith {
                return 'Credentials'
            }

            Mock -CommandName Reset-MSCloudLoginConnectionProfileContext -MockWith {
            }

            Mock -CommandName Get-PSSession -MockWith {
            }

            Mock -CommandName Remove-PSSession -MockWith {
            }

            Mock -CommandName Get-AcceptedDomain -MockWith {
            }

            Mock -CommandName Enable-SmtpDaneInbound -MockWith {
            }

            Mock -CommandName Disable-SmtpDaneInbound -MockWith {
            }

            Mock -CommandName New-M365DSCConnection -MockWith {
                return "Credentials"
            }

            # Mock Write-Host to hide output during the tests
            Mock -CommandName Write-Host -MockWith {
            }
            $Script:exportedInstances =$null
            $Script:ExportMode = $false
        }

        # Test contexts
        Context -Name "The EXOSmtpDaneInbound should exist but it DOES NOT" -Fixture {
            BeforeAll {
                $testParams = @{
                    DomainName = "fakedomain.com"
                    Ensure     = "Present"
                    Credential = $Credential;
                }

                Mock -CommandName Get-AcceptedDomain -MockWith {
                    return @{
                        DomainName     = "fakedomain.com"
                        SmtpDaneStatus = "Disabled"
                    }
                }
            }
            It 'Should return Values from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be 'Absent'
            }
            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }
            It 'Should Enable SmtpDaneInbound from the Set method' {
                Set-TargetResource @testParams
                Should -Invoke -CommandName Enable-SmtpDaneInbound -Exactly 1
            }
        }

        Context -Name "The EXOSmtpDaneInbound exists but it SHOULD NOT" -Fixture {
            BeforeAll {
                $testParams = @{
                    DomainName = "fakedomain.com"
                    Ensure     = "Absent"
                    Credential = $Credential;
                }

                Mock -CommandName Get-AcceptedDomain -MockWith {
                    return @{
                        DomainName     = "fakedomain.com"
                        SmtpDaneStatus = "Enabled"
                    }
                }
            }

            It 'Should return Values from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be 'Present'
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It 'Should disable SmtpDaneInbound from the Set method' {
                Set-TargetResource @testParams
                Should -Invoke -CommandName Disable-SmtpDaneInbound -Exactly 1
            }
        }

        Context -Name "The EXOSmtpDaneInbound Exists and Values are already in the desired state" -Fixture {
            BeforeAll {
                $testParams = @{
                    DomainName = "fakedomain.com"
                    Ensure     = "Present"
                    Credential = $Credential;
                }

                Mock -CommandName Get-AcceptedDomain -MockWith {
                    return @{
                        DomainName     = "fakedomain.com"
                        SmtpDaneStatus = "Enabled"
                    }
                }
            }

            It 'Should return true from the Test method' {
                Test-TargetResource @testParams | Should -Be $true
            }
        }

        Context -Name 'ReverseDSC Tests' -Fixture {
            BeforeAll {
                $Global:CurrentModeIsExport = $true
                $Global:PartialExportFileName = "$(New-Guid).partial.ps1"
                $testParams = @{
                    Credential = $Credential
                }

                Mock -CommandName Get-AcceptedDomain -MockWith {
                    return @(
                        @{
                            DomainName            = "fakedomain.com"
                            SmtpDaneStatus        = 'Disabled'
                        },
                        @{
                            DomainName            = "otherfakedomain.com"
                            SmtpDaneStatus        = 'Enabled'
                        }
                    )
                }
            }

            It 'Should Reverse Engineer resource from the Export method' {
                $result = Export-TargetResource @testParams
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
