# @summary Class responsible for installing k3s
class k3s::install {
  case $k3s::installation_mode {
    'script': {
      archive { '/tmp/k3s_install.sh':
        ensure           => present,
        filename         => '/tmp/k3s_install.sh',
        source           => 'https://get.k3s.io',
        creates          => '/tmp/k3s_install.sh',
        download_options => ['-s'],
        cleanup          => false,
      }

      file { '/tmp/k3s_install.sh':
        ensure  => file,
        mode    => '0744',
        require => [
          Archive['/tmp/k3s_install.sh'],
        ],
      }

       $environment = $k3s::type ? {
         'init'  => [
           "INSTALL_K3S_EXEC=server --disable=traefik",
           "INSTALL_K3S_SKIP_START=true",
           "INSTALL_K3S_VERSION=${k3s::binary_version}",
         ],
         'joining'  => [
           "INSTALL_K3S_EXEC=server --disable=traefik",
           "INSTALL_K3S_SKIP_START=true",
           "INSTALL_K3S_VERSION=${k3s::binary_version}",
         ],
         'node'  => [
           "INSTALL_K3S_EXEC=agent",
           "INSTALL_K3S_SKIP_START=true",
           "INSTALL_K3S_VERSION=${k3s::binary_version}",
         ]
      }

      exec { 'k3s_install':
        command     => '/tmp/k3s_install.sh',
        # on first init, we do not want it ot start, after that, no problems
        environment => $environment,
        require     => [
          File['/tmp/k3s_install.sh'],
        ],
        subscribe   => [
          Archive['/tmp/k3s_install.sh'],
        ],
        refreshonly => true,
      }
    }

    'binary': {
      case $facts['os']['architecture'] {
        'amd64', 'x86_64': {
          $binary_arch = 'k3s'
          $checksum_arch = 'sha256sum-amd64.txt'
        }
        'arm64': {
          $binary_arch = 'k3s-arm64'
          $checksum_arch = 'sha256sum-arm64.txt'
        }
        'armhf': {
          $binary_arch = 'k3s-armhf'
          $checksum_arch = 'sha256sum-arm.txt'
        }
        default: {
          fail('No valid architecture provided.')
        }
      }
      $k3s_url = "https://github.com/rancher/k3s/releases/download/${k3s::binary_version}/${binary_arch}"
      $k3s_checksum_url = "https://github.com/rancher/k3s/releases/download/${k3s::binary_version}/${checksum_arch}"

      archive { $k3s::binary_path:
        ensure           => present,
        source           => $k3s_url,
        checksum_url     => $k3s_checksum_url,
        checksum_type    => 'sha256',
        cleanup          => false,
        creates          => $k3s::binary_path,
        download_options => '-S',
      }

      file { $k3s::binary_path:
        ensure  => file,
        mode    => '0755',
        require => [
          Archive[$k3s::binary_path],
        ],
      }
    }

    default: {
      fail('No valid installation mode provided.')
    }
  }
}
