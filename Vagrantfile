# -*- mode: ruby -*-
# vi: set ft=ruby :

require "json"

ISO_PATH = File.expand_path("rhel-9.7-x86_64-dvd.iso", __dir__)
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
CLIENT_DISK1 = File.join(LAB_DISKS_DIR, "clientvm-disk1#{DISK_SUFFIX}.vdi")
CLIENT_DISK2 = File.join(LAB_DISKS_DIR, "clientvm-disk2#{DISK_SUFFIX}.vdi")

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
SERVER_SCENARIO_SCRIPT = ensure_script_exists(resolve_scenario_script(ACTIVE_RUN, "servervm"), "servervm")
CLIENT_SCENARIO_SCRIPT = ensure_script_exists(resolve_scenario_script(ACTIVE_RUN, "clientvm"), "clientvm")

Vagrant.configure("2") do |config|
  config.vm.box = "generic/rocky9"
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

  config.vm.define "servervm" do |server|
    server.vm.hostname = "servervm"
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

  config.vm.define "clientvm" do |client|
    client.vm.hostname = "clientvm"
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
