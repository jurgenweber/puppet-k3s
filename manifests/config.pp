# @summary Class responsible for configurationk3s
class k3s::config (
  String $token_secret,
  Enum['init','joining'] $type,
) {
  # type as in the 'init'/first master or a 'joining' master
  case $type {
    'init': {
      exec { 'init-cluster':
        command     => "${k3s::binary_path} server --cluster-init --disable traefik >/var/log/k3s-init.log 2>&1 &",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${token_secret}"
        ],
        logoutput   => true,
        provider    => 'shell',
        timeout     => 600
      }
      # this is the exporter resource, with the ip details, https://www.puppet.com/docs/puppet/7/lang_exported.html
      @@exec { 'join-cluster':
        command     => "${k3s::binary_path} server --server ${::ipaddress}:6443 >/var/log/k3s-init.log 2>&1",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${token_secret}"
        ],
        logoutput   => true,
        provider    => 'shell',
        tag         => ['join-cluster']
        timeout     => 600
      }
      @@exec { 'node-join-cluster':
        command     => "${k3s::binary_path} agent --server ${::ipaddress}:6443 >/var/log/k3s-init.log 2>&1",
        # apparently makes this data dir; https://docs.k3s.io/cli/server#data
        creates     => '/var/lib/rancher/k3s',
        environment => [
          "K3S_TOKEN=${token_secret}"
        ],
        logoutput   => true,
        provider    => 'shell',
        tag         => ['node-join-cluster']
        timeout     => 600
      }
    }

    'joining': {
      Exec <<| tag == 'join-cluster' |>>
    }

    'node': {
      Exec <<| tag == 'node-join-cluster' |>>
    }

    default: {
      fail('No valid configuration type provided.')
    }
  }
}
