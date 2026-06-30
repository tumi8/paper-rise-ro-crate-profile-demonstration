action: reset
note: Synthetic reset action description. This is not a literal executed shell command;
  reset execution is interface- and node-type specific.
node:
  id: dogecoincash
  fqdn: dogecoincash.blockchain.net.cit.tum.de
  node_type: host
execution:
  initialization_interface:
    id: dogecoincash
    type: ipmi
    transport: ipmitool (IPMI)
    details:
      dnsname: dogecoincash.ipmi
  strategy: power_cycle_if_running_then_start
  steps:
  - power_off_if_running
  - power_on
  implementation_hint: ipmitool chassis power off/on (with boot device handling)
  access_levels:
  - all
boot:
  booted_image: default/debian-bullseye@2021-12-21T02:29:06+00:00
  boot_parameters: []
