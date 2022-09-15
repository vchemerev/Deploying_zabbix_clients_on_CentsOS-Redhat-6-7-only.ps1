
#This script for installing zabbix clients on CentsOS/Redhat 6 or 7 versions only

add-type @"
using System.Net;

using System.Security.Cryptography.X509Certificates;

public class TrustAllCertsPolicy : ICertificatePolicy {

  public bool CheckValidationResult(

  ServicePoint srvPoint, X509Certificate certificate,

  WebRequest request, int certificateProblem) {

  return true;

  }

}

"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Specifying credentials
$vcenter = "vcentername"
$username = "vcenter-username"
$password = 'vcenter-password'

$zabbix_proxy_server="192.0.2.1" #put your zabbix server ip or name
$source_dir_rhel6="C:\DistrosFolder\Zabbix\RHEL 6\zabbix-agent-5.0.3-1.el6.x86_64.rpm"
$source_dir_rhel7="C:\DistrosFolder\Zabbix\RHEL 7\zabbix-agent-5.0.3-1.el7.x86_64.rpm"

# connecting to vcenter
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
connect-viserver -server $vcenter -user $username -password $password

# Specifying credentials for CentsOS/Redhat 
$LinuxUser1 = "root"   
$LinuxPassword1 = ConvertTo-SecureString "password" -AsPlainText -force 
$linux_cred1 = New-Object System.Management.Automation.PSCredential ($LinuxUser1, $LinuxPassword1)
$dest_dir_linux="/root" # directory for copying a zabbix package 


#Put your VMs here
$vms= @(
	'VM01'
        'VM02'
        'VM03'
)
#Cheking version of OS
$s0=0
foreach ( $vm in $vms )
{
$s0=[int]$s0+1
echo "$s0 of $($($vms).Count)"

    
    $ST_chekingOSversion= "grep '^VERSION=' /etc/os-release"
    $OSversion=(Invoke-VMScript -VM $vm -ScriptText $ST_chekingOSversion -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
    echo "$vm OS verison is $OSversion"
    
	if ($OSversion -cmatch '"6.')  {
       Copy-VMGuestFile -Source $source_dir_rhel6 -Destination $dest_dir_linux -VM $vm -LocalToGuest -GuestCredential $linux_cred1 
       $TS_install_zabbix= "rpm -ivh zabbix-agent-5.0.3-1.el6.x86_64.rpm"
       (Invoke-VMScript -VM $vm -ScriptText $TS_install_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
       $TS_edit_conf_zabbix="sed -i 's/^ServerActive=127.0.0.1/ServerActive=$zabbix_proxy_server/;s/^Server=127.0.0.1/Server=$zabbix_proxy_server/g;s/^Hostname=*.*$/Hostname=$vm/g' /etc/zabbix/zabbix_agentd.conf"
       (Invoke-VMScript -VM $vm -ScriptText $TS_edit_conf_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
       $TS_start_zabbix="/etc/init.d/zabbix-agent start"
       (Invoke-VMScript -VM $vm -ScriptText $TS_start_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
       $TS_autologon_zabbix="chkconfig zabbix-agent on"
       (Invoke-VMScript -VM $vm -ScriptText $TS_autologon_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
		echo "There is OS 6 version, finish the script"
    }
    if ($OSversion -cmatch '"7.')  {
        Copy-VMGuestFile -Source $source_dir_rhel7 -Destination $dest_dir_linux -VM $vm -LocalToGuest -GuestCredential $linux_cred1
       $TS_install_zabbix= "rpm -ivh zabbix-agent-5.0.3-1.el7.x86_64.rpm" 
       (Invoke-VMScript -VM $vm -ScriptText $TS_install_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
       $TS_edit_conf_zabbix="sed -i 's/^ServerActive=127.0.0.1/ServerActive=$zabbix_proxy_server/;s/^Server=127.0.0.1/Server=$zabbix_proxy_server/g;s/^Hostname=*.*$/Hostname=$vm/g' /etc/zabbix/zabbix_agentd.conf"
       (Invoke-VMScript -VM $vm -ScriptText $TS_edit_conf_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
       $TS_start_zabbix="systemctl start zabbix-agent.service"
       (Invoke-VMScript -VM $vm -ScriptText $TS_start_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
       $TS_autologon_zabbix="systemctl enable zabbix-agent.service"
       (Invoke-VMScript -VM $vm -ScriptText $TS_autologon_zabbix -GuestCredential $linux_cred1 -ScriptType Bash).ScriptOutput
       
        echo "There is OS 7 version, finish the script"
    }

}
