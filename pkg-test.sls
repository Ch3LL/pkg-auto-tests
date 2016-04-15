{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set upgrade_salt_version = salt['pillar.get']('upgrade_salt_version', '') %}
{% set repo_pkg = salt['pillar.get']('repo_pkg', '') %}
{% set latest = salt['pillar.get']('latest', '') %}
{% set dev = salt['pillar.get']('dev', '') %}
{% set cloud_profile = salt['pillar.get']('cloud_profile', '') %}
{% set orch_master = salt['pillar.get']('orch_master', '') %}
{% set username = salt['pillar.get']('username', '') %}
{% set upgrade = salt['pillar.get']('upgrade', '') %}
{% set hosts = [] %}

{% for profile in cloud_profile %}
{% set host = username + profile %}
{% do hosts.append(host) %}
create_{{ host }}:
  salt.function:
    - name: salt_cluster.create_node
    - tgt: {{ orch_master }}
    - arg:
      - {{ host }}
      - {{ profile }}

sleep_{{ host }}:
  salt.function:
    - name: test.sleep
    - tgt: {{ orch_master }}
    - arg:
      - 120

{% if '5' in host %}
install_python:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -ir "mv /var/lib/rpm/Pubkeys /tmp/; rpm --rebuilddb; yum -y install epel-release; yum -y install python26-libs; yum -y install libffi; yum -y install python26"
{% endif %}

verify_host_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -i test.ping
{% endfor %}

test_install:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_install.saltstack
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}
        latest: {{ latest }}
        repo_pkg: {{ repo_pkg }}
        upgrade: False

test_setup:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_setup
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}

test_run:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_run
    - pillar:
        salt_version: {{ salt_version }}
        dev: {{ dev }}

{% if upgrade %}
test_upgrade:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_install.saltstack
    - pillar:
        salt_version: {{ upgrade_salt_version }}
        dev: {{ dev }}
        latest: {{ latest }}
        repo_pkg: {{ repo_pkg }}
        upgrade: {{ upgrade }}

test_upgrade_run:
  salt.state:
    - tgt: {{ hosts }}
    - tgt_type: list
    - ssh: 'true'
    - sls:
      - test_run
    - pillar:
        salt_version: {{ upgrade_salt_version }}
        dev: {{ dev }}
{% endif %}

