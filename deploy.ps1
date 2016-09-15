configuration cts_webservers
{
param(
[Parameter(Mandatory=$true)][ValidateNotNullorEmpty()][String]$NodeName,
[Parameter(Mandatory=$false)][ValidateNotNullorEmpty()]$AllNodesData,
[Parameter(Mandatory=$false)][ValidateNotNullorEmpty()]$AppPoolConfig,
[Parameter(Mandatory=$false)][ValidateNotNullorEmpty()]$Websites,
[Parameter(Mandatory=$false)][ValidateNotNullorEmpty()]$IisConfig
)

    # Modules must exist on target pull server
	Import-DSCResource -ModuleName xWebAdministration,PSDesiredStateConfiguration
  
    Node "Localhost"
    {

        #################################################################
        # Configure LCM
        LocalConfigurationManager
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
        #################################################################
		#################################################################
        # Enable IIS Central Certificate Store
        if ($IISConfig.CcsEnabled -eq $true)
        {
          cCentralCertificateStore EnableCcs
          {
            Ensure = "Present"
            CertStoreLocation = $IISConfig.CcsPath
            Credential = $Credential_iis_cert_store
            PrivateKeyPassword = $Credential_iis_ccs_key
          }
        }
        #################################################################
        
        #################################################################
        # Enable IIS shared config
        if ($IISConfig.SharedConfigEnabled -eq $true)
        {
         
			#Enable shared configuration on a unc path
			cSharedConfig EnableSharedConfig
			{
				Ensure = "Present"
				Credential = $Credential_svc_deploy_ad
				DestinationPath = $IISConfig.SharedConfigPath 
			}
          
			File DCOMPerm
			{
				Ensure          = "Present"
				Credential = $Credential_svc_deploy_ad
				SourcePath = $IISconfig.DcomPermLocation
				DestinationPath = "%ProgramFiles%\DCOMPerm\DCOMPerm.exe"
			}
		}
		
		#################################################################
        # Create websites
        foreach ($Website in $Websites)
        {
          
        # Create AppPool
        xWebAppPool "AppPool_$($WebName)"
        {
            Name = "AppPool_" + $Website.Name
            Ensure = "Present"
            Credential = $Credentials.Value
            identityType = "SpecificUser"
            startMode = $AppPoolConfig.startMode
            rapidFailProtection = $AppPoolConfig.rapidFailProtection
            idleTimeout = $AppPoolConfig.idleTimeout
            DependsOn = "[File]Folder_$($WebName)"
        }

        #endregion
        
		 $defaultIpAddress = Get-NetIPAddress | Where-Object AddressFamily -EQ IPv4 | Where-Object InterfaceAlias -EQ Ethernet | foreach {$_.IPAddress}

        #region Create binding records  
        # Create normal bindings
        $bindings = @()
        foreach($binding in $Website.Bindings)
        {
            switch ($binding.Protocol)
            {
                # Add http bindings
                "http" {
                            $bindings += MSFT_xWebBindingInformation
                            {
                                Protocol = $binding.Protocol
                                IPAddress = $binding.IPAddress
                                Port = $binding.Port
                                HostName = $binding.hostName
                            }
                        }
                # Add https bindings
                "https" {
                            $bindings += MSFT_xWebBindingInformation
                            {
                                Protocol = $binding.Protocol
                                IPAddress = if ($binding.IPAddress -eq "DefaultIp") {$defaultIpAddress} else {$binding.IPAddress}
                                Port = $binding.Port
                                HostName = $binding.hostName
                                CertificateThumbprint = $binding.CertificateThumbprint
			                    SslFlags = $binding.SslFlags
                            }
                        }
            }
          
        }#endforeach

		# Add all reseller bindings
        foreach($reseller in $Website.Resellers.HostHeaders)
        {
			foreach ($binding in $Website.Resellers.BindingType)
            {
                switch ($binding.Protocol)
                {
                    # Add http bindings
                    "http" {
                                $bindings += MSFT_xWebBindingInformation
                                {
                                    Protocol = $binding.Protocol
                                    IPAddress = $binding.IPAddress
                                    Port = $binding.Port
                                    HostName = $reseller
                                }
                            }
                    # Add https bindings
                    "https" {
                                $bindings += MSFT_xWebBindingInformation
                                {
                                    Protocol = $binding.Protocol
                                    IPAddress = $binding.IPAddress
                                    Port = $binding.Port
                                    HostName = $reseller
                                    CertificateThumbprint = $binding.CertificateThumbprint
			                        SslFlags = $binding.SslFlags
                                }
                            }
                }

			}
		}
        #endregion

        #region Create the IIS site
        xWebsite "Website_$($WebName)"
        {
            Name = $Website.Name
            Ensure = "Present"
            State = "Started"
            PhysicalPath = $Website.Path
			LogPath = $Website.LogPath
            ApplicationPool = "AppPool_" + $Website.Name
            BindingInfo = $bindings
            DependsOn = "[xWebAppPool]AppPool_$($WebName)"
        }

        #endregion

        
      }#endeach
	}
}