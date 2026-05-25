# battery-mqtt-monitor

Publishes battery status to an MQTT broker every minute. Works on any Linux system with `upower` and `systemd`. Integrates with any platform that can subscribe to MQTT topics.

## What it publishes

**Topic:** `devices/<hostname>/battery`

**Payload:**
```json
{
  "charge": 87,
  "status": "discharging",
  "time_remaining": "1h 23min",
  "wear": 12.5,
  "timestamp": "2025-08-08 10:30:00"
}
```

| Field | Type | Description |
|---|---|---|
| `charge` | number | Battery percentage (0–100) |
| `status` | string | `charging`, `discharging`, or `full` |
| `time_remaining` | string | Estimated time left, empty when charging |
| `wear` | number | Battery degradation percentage since new |
| `timestamp` | string | Time of last reading (YYYY-MM-DD HH:MM:SS) |

## Requirements

- Ubuntu 20.04+ or Debian 11+
- `upower`, `jq`, `mosquitto-clients`, `bc` (installed automatically as dependencies)
- An MQTT broker accessible on your network (e.g. Mosquitto)

## Installation

### Option 1 — Download the .deb (recommended)

```bash
wget https://github.com/miplatas/battery-mqtt-monitor/releases/download/v1.0.0/battery-mqtt-monitor_1.0.0_all.deb
sudo dpkg -i battery-mqtt-monitor_1.0.0_all.deb
```

During installation you will be asked for your MQTT broker IP, port, and credentials.

### Option 2 — Build from source

```bash
git clone https://github.com/miplatas/battery-mqtt-monitor
cd battery-mqtt-monitor
make
sudo dpkg -i releases/battery-mqtt-monitor_1.0.0_all.deb
```

## Configuration

Config file is stored at `/etc/battery-mqtt-monitor/config`:

```bash
MQTT_BROKER="192.168.1.1"
MQTT_PORT="1883"
MQTT_USER="myuser"
MQTT_PASS="mypassword"
```

After editing, restart the timer:

```bash
sudo systemctl restart battery-mqtt-monitor.timer
```

## Verify it's working

Subscribe to the topic from any machine on your network:

```bash
mosquitto_sub -h 192.168.1.1 -t "devices/+/battery" -v
```

## Examples

### Node-RED

Use an **MQTT In** node subscribed to `devices/+/battery`, then a **JSON** node to parse the payload, and connect to any output (dashboard gauge, InfluxDB, notification, etc.):

```
[MQTT In: devices/+/battery] → [JSON] → [your logic]
```

Access fields in a Function node:
```javascript
const charge = msg.payload.charge;
const status = msg.payload.status;

if (charge < 20 && status === "discharging") {
    msg.payload = "Battery low: " + charge + "%";
    return msg;
}
```

---

### Grafana + InfluxDB

Use a **Telegraf** MQTT consumer to forward messages to InfluxDB, then visualize in Grafana:

```toml
# telegraf.conf
[[inputs.mqtt_consumer]]
  servers = ["tcp://192.168.1.1:1883"]
  topics  = ["devices/+/battery"]
  data_format = "json"
  json_string_fields = ["status", "time_remaining", "timestamp"]
```

---

### Home Assistant (manual YAML)

Add to your `configuration.yaml`:

```yaml
mqtt:
  sensor:
    - name: "Battery Charge"
      state_topic: "devices/my-laptop/battery"
      value_template: "{{ value_json.charge }}"
      unit_of_measurement: "%"
      device_class: battery

    - name: "Battery Status"
      state_topic: "devices/my-laptop/battery"
      value_template: "{{ value_json.status }}"

    - name: "Battery Time Remaining"
      state_topic: "devices/my-laptop/battery"
      value_template: "{{ value_json.time_remaining }}"

    - name: "Battery Wear"
      state_topic: "devices/my-laptop/battery"
      value_template: "{{ value_json.wear }}"
      unit_of_measurement: "%"
```

---

### Python (paho-mqtt)

```python
import paho.mqtt.client as mqtt
import json

def on_message(client, userdata, msg):
    data = json.loads(msg.payload)
    print(f"Charge: {data['charge']}%  Status: {data['status']}")

client = mqtt.Client()
client.connect("192.168.1.1", 1883)
client.subscribe("devices/+/battery")
client.on_message = on_message
client.loop_forever()
```

---

### OpenHAB

Define a channel in your `.things` file:

```
Thing mqtt:topic:battery "Battery Monitor" (mqtt:broker:myBroker) {
    Channels:
        Type number : charge        [ stateTopic="devices/my-laptop/battery", transformationPattern="JSONPATH:$.charge" ]
        Type string : status        [ stateTopic="devices/my-laptop/battery", transformationPattern="JSONPATH:$.status" ]
        Type number : wear          [ stateTopic="devices/my-laptop/battery", transformationPattern="JSONPATH:$.wear" ]
}
```

## Uninstall

```bash
sudo dpkg -r battery-mqtt-monitor
```

## License

GNU General Public License v3.0
