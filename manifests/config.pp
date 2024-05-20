# @summary Class responsible for configurationk3s
class k3s::config () {
  # type as in the 'init'/first master or a 'joining' master
  case $k3s::type {
    'init': {
      exec { 'init-cluster':
        command     => "${k3s::binary_path} server --cluster-init --disable servicelb --disable traefik >/var/log/k3s-init.log 2>&1 &",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${k3s::token_secret}"
        ],
        logoutput   => true,
        provider    => 'shell',
        timeout     => 600
      }
      file { '/etc/rancher/k3s/config.yaml':
        ensure  => file,
        content => template('k3s/config.yaml.erb'),
      }
      file_line { 'add-servicelb-disable-to-systemd':
        path    => '/etc/systemd/system/k3s.service',
        line    => '  --disable traefik --disable servicelb \\ ',
        match   => '.*\'--disable traefik\' \\ ',
      }
      # this is the exporter resource, with the ip details, https://www.puppet.com/docs/puppet/7/lang_exported.html
      @@exec { 'join-cluster':
        command     => "${k3s::binary_path} server --disable servicelb --disable traefik >/var/log/k3s-init.log 2>&1 &",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${k3s::token_secret}",
          "K3S_URL=https://${::ipaddress}:6443"
        ],
        logoutput   => true,
        provider    => 'shell',
        tag         => ['join-cluster'],
        timeout     => 600
      }
      @@exec { 'node-join-cluster':
        command     => "${k3s::binary_path} agent >/var/log/k3s-init.log 2>&1 &",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${k3s::token_secret}",
          "K3S_URL=https://${::ipaddress}:6443"
        ],
        logoutput   => true,
        provider    => 'shell',
        tag         => ['node-join-cluster'],
        timeout     => 600
      }
      @@file_line { 'add-k3s-url-to-systemd':
        path    => '/etc/systemd/system/k3s-agent.service.env',
        line    => "K3S_URL=https://${::ipaddress}:6443",
        tag     => ['node-join-cluster'],
      }
    }

    'joining': {
      file { '/etc/rancher/k3s/config.yaml':
        ensure  => file,
        content => template('k3s/config.yaml.erb'),
      }
      file_line { 'add-servicelb-disable-to-systemd':
        path    => '/etc/systemd/system/k3s.service',
        line    => ' --disable traefik --disable servicelb \\ ',
        match   => '.*\'--disable traefik\' \\ ',
      }

      Exec <<| tag == 'join-cluster' |>>
    }

    'node': {
      Exec <<| tag == 'node-join-cluster' |>>
      File_line <<| tag == 'node-join-cluster' |>>

      file_line { 'add-env-token-to-systemd':
        path    => '/etc/systemd/system/k3s-agent.service.env',
        line    => "K3S_TOKEN=${$k3s::token_secret}",
      }
    }

    default: {
      fail('No valid configuration type provided.')
    }
  }
}
