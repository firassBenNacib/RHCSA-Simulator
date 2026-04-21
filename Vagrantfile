require "json"
require "rbconfig"

RHCSA_PROFILE = ENV.fetch("RHCSA_PROFILE", "rhel9").downcase
DEFAULT_ISO_BY_PROFILE = {
  "rhel9" => "rhel-9.7-x86_64-dvd.iso",
  "rhel10" => "rhel-10.1-x86_64-dvd.iso"
}
DEFAULT_BOX_BY_PROFILE = {
  "rhel9" => "generic/rocky9",
  "rhel10" => "rockylinux/10"
}

unless DEFAULT_ISO_BY_PROFILE.key?(RHCSA_PROFILE)
  raise "Unsupported RHCSA_PROFILE '#{RHCSA_PROFILE}'. Use rhel9 or rhel10."
end

def host_supports_x86_64_v3?
  cpu = RbConfig::CONFIG.fetch("host_cpu", "").downcase
  return true unless cpu.include?("x86_64") || cpu.include?("amd64")
  return true unless File.file?("/proc/cpuinfo")

  flags = File.read("/proc/cpuinfo", encoding: "UTF-8", invalid: :replace, undef: :replace).lines.grep(/^flags\s*:/).first.to_s
  required = %w[avx avx2 bmi1 bmi2 f16c fma movbe osxsave]
  required.all? { |flag| flags.include?(" #{flag} ") } &&
    (flags.include?(" lzcnt ") || flags.include?(" abm "))
end

if RHCSA_PROFILE == "rhel10" && !host_supports_x86_64_v3?
  raise "RHCSA_PROFILE=rhel10 requires an x86-64-v3 capable host CPU. Use RHCSA_PROFILE=rhel9 on older hosts."
end

ISO_NAME = ENV.fetch("RHCSA_ISO", DEFAULT_ISO_BY_PROFILE.fetch(RHCSA_PROFILE))
BOX_NAME = ENV.fetch("RHCSA_BOX", DEFAULT_BOX_BY_PROFILE.fetch(RHCSA_PROFILE))
ISO_PATH = File.expand_path(ISO_NAME, __dir__)
raise "Missing ISO: #{ISO_PATH}" unless File.exist?(ISO_PATH)

SSH_COMMAND_CANDIDATES = [
  File.join(ENV.fetch("SystemRoot", "C:/Windows"), "System32", "OpenSSH", "ssh.exe"),
  "C:/Windows/System32/OpenSSH/ssh.exe",
  "C:/Program Files/Git/usr/bin/ssh.exe",
  "C:/Program Files/Git/bin/ssh.exe"
].uniq

SSH_COMMAND_PATH = SSH_COMMAND_CANDIDATES.find { |path| File.file?(path) }

LAB_DISKS_DIR = File.join(__dir__, ".lab-disks")

DISK_GENERATION_PATH = File.join(__dir__, ".lab-state", "disk-generation.txt")
DISK_GENERATION = if File.file?(DISK_GENERATION_PATH)
  File.read(DISK_GENERATION_PATH, encoding: "bom|utf-8").strip.gsub(/[^0-9A-Za-z_-]/, "")
else
  ""
end

DISK_SUFFIX = DISK_GENERATION.empty? ? "" : "-#{DISK_GENERATION}"
CLIENT_DISK1 = File.join(LAB_DISKS_DIR, "client-disk1#{DISK_SUFFIX}.vdi")
CLIENT_DISK2 = File.join(LAB_DISKS_DIR, "client-disk2#{DISK_SUFFIX}.vdi")

ACTIVE_RUN_PATH = File.join(__dir__, ".lab-state", "active-run.json")
CHECK_SERVER_SCRIPT = File.join(__dir__, ".lab-state", "check-server.sh")
CHECK_CLIENT_SCRIPT = File.join(__dir__, ".lab-state", "check-client.sh")

def load_active_run(path)
  return nil unless File.exist?(path)

  raw_json = File.read(path, encoding: "bom|utf-8")
  JSON.parse(raw_json.sub(/\A\uFEFF/, ""))
rescue JSON::ParserError => e
  raise "Invalid active run state in #{path}: #{e.message}"
end

def resolve_scenario_script(active_run, machine_key)
  return nil unless active_run

  relative_path = active_run.dig("scenario", "vm_scripts", machine_key)
  legacy_key = machine_key == "server" ? "servervm" : "clientvm"
  relative_path = active_run.dig("scenario", "vm_scripts", legacy_key) if relative_path.nil?
  return nil if relative_path.nil? || relative_path.to_s.strip.empty?

  File.expand_path(relative_path, __dir__)
end

def ensure_script_exists(path, label)
  return nil unless path

  raise "Missing #{label} scenario script: #{path}" unless File.file?(path)

  path
end

def scenario_env(active_run)
  return {} unless active_run

  {
    "RHCSA_RUN_ID" => active_run["run_id"].to_s,
    "RHCSA_SCENARIO_ID" => active_run.dig("scenario", "id").to_s,
    "RHCSA_SCENARIO_MODE" => active_run["mode"].to_s
  }
end

ACTIVE_RUN = load_active_run(ACTIVE_RUN_PATH)
SCENARIO_ENV = scenario_env(ACTIVE_RUN)
SERVER_SCENARIO_SCRIPT = ensure_script_exists(resolve_scenario_script(ACTIVE_RUN, "server"), "server")
CLIENT_SCENARIO_SCRIPT = ensure_script_exists(resolve_scenario_script(ACTIVE_RUN, "client"), "client")

Vagrant.configure("2") do |config|
  config.vm.box = BOX_NAME
  config.vm.box_check_update = false
  config.ssh.insert_key = false
  config.ssh.keys_only = true
  config.ssh.connect_timeout = 30
  config.ssh.connect_retries = 15
  config.ssh.connect_retry_delay = 2
  config.ssh.ssh_command = SSH_COMMAND_PATH if SSH_COMMAND_PATH
  config.vm.boot_timeout = 900
  config.vm.graceful_halt_timeout = 60
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.define "server" do |server|
    server.vm.hostname = "server"
    server.vm.network "private_network", ip: "192.168.122.3"

    server.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = 2048
      vb.cpus = 2

      vb.customize [
        "storageattach", :id,
        "--storagectl", "IDE Controller",
        "--port", "1",
        "--device", "0",
        "--type", "dvddrive",
        "--medium", ISO_PATH
      ]
    end

    server.vm.provision "shell", path: "guest/common_setup.sh"
    server.vm.provision "shell", path: "guest/server_setup.sh"
    if SERVER_SCENARIO_SCRIPT
      server.vm.provision "shell",
        path: SERVER_SCENARIO_SCRIPT,
        env: SCENARIO_ENV,
        run: "never",
        name: "scenario-server"
    end
    if File.file?(CHECK_SERVER_SCRIPT)
      server.vm.provision "shell",
        path: CHECK_SERVER_SCRIPT,
        run: "never",
        name: "check-server"
    end
  end

  config.vm.define "client" do |client|
    client.vm.hostname = "client"
    client.vm.network "private_network", ip: "192.168.122.2"

    client.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = 2048
      vb.cpus = 2

      vb.customize [
        "storageattach", :id,
        "--storagectl", "SATA Controller",
        "--port", "1",
        "--device", "0",
        "--type", "hdd",
        "--medium", CLIENT_DISK1
      ]

      vb.customize [
        "storageattach", :id,
        "--storagectl", "SATA Controller",
        "--port", "2",
        "--device", "0",
        "--type", "hdd",
        "--medium", CLIENT_DISK2
      ]
    end

    client.vm.provision "shell", path: "guest/common_setup.sh"
    client.vm.provision "shell", path: "guest/client_setup.sh"
    if CLIENT_SCENARIO_SCRIPT
      client.vm.provision "shell",
        path: CLIENT_SCENARIO_SCRIPT,
        env: SCENARIO_ENV,
        run: "never",
        name: "scenario-client"
    end
    if File.file?(CHECK_CLIENT_SCRIPT)
      client.vm.provision "shell",
        path: CHECK_CLIENT_SCRIPT,
        run: "never",
        name: "check-client"
    end
  end
end
