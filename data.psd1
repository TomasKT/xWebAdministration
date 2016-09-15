@{
    NodeName = "r1_CTS_web_webapp"
	
	IISConfig = @{
		SharedConfig = $false
		SharedConfigPath = ""
		CcsEnabled = $true
		CcsPath = "\\cts.p\IIS\iis_certs123" 
		DcomPermLocation = "\\TMS-DC01p.cts.p\packages\packages-exe\DComPerm.exe"
	}

    AppPoolConfig = @{
	startMode = "AlwaysRunning"
	rapidFailProtection = $false
	idleTimeout = "00:30:00"
	}

    Websites = @(
    @{
    Name = "dotmailer-web"
    Path = "f:\webroot\Tomaskt-web"
	LogPath = "l:\logs\Tomaskt-web"
    Credentials = "cts_svc_iis_webapp"
    

    Bindings = @(
	    @{
          Protocol = "http"
          IPAddress = "*"
          Port = "80"
          HostName = "login.Tomaskt.com"
        }, 
        @{
          Protocol = "http"
          IPAddress = "*"
          Port = "80"
          HostName = "r1-app.Tomaskt.com"
        },
        @{
          Protocol = "http"
          IPAddress = "*"
          Port = "80"
          HostName = "*"
        },
       @{
          Protocol = "https"
          IPAddress = "*"
          Port = "443"
          HostName = "r1-app.Tomaskt.com"
          CertificateThumbprint = $null
          SslFlags = 2
        }
    ) #endbindings

    Resellers = @(
            @{
            BindingType = @(
                    @{
                    Protocol = "https"
                    IPAddress = "*"
                    Port = "443"
                    SslFlags = 2
                    CertificateThumbprint = $null
                }
            )#endBindings
            #Up here we have just few HostHeaders, but originaly it would contain around 300 host headers.
            HostHeaders = @(		
				"admin.101Tomaskt.co.uk"
				"admin.18-35tomaskt.co.uk"
				"admin.3rdtomaskt-email.com"
				"admin.450Tomaskt.com"
				)
			}
	}
}