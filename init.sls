{% set salt_version = salt['pillar.get']('salt_version', '') %}
{% set cloud_profile = salt['pillar.get']('cloud_profile', '') %}
{% set orch_master = 'ch3ll-master*' %}

{% for profile in cloud_profile %}
{% set host = 'ch3ll-' + profile %}
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

verify_host_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: {{ orch_master }}
    - arg:
      - salt-ssh {{ host }} -i test.ping
{% endfor %}
