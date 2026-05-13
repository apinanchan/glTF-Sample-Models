# Ragnarok Online Private Server

**Specs:** Episode 21 | Class 4 (4th Jobs) | Max Level 275/60 | Renewal Mode

Server engine: [rAthena](https://github.com/rathena/rathena)

---

## Quick Start (Docker - แนะนำ)

ต้องการแค่ Docker และ Docker Compose เท่านั้น

```bash
cd ragnarok-server
docker compose up --build -d
```

รอประมาณ 10-15 นาทีสำหรับการ compile ครั้งแรก จากนั้น server จะพร้อมใช้งาน

### Ports
| Service      | Port |
|--------------|------|
| Login Server | 6900 |
| Char Server  | 6121 |
| Map Server   | 5121 |

### GM Account เริ่มต้น
- **Username:** `admin`
- **Password:** `admin`
- **Group:** 99 (GM สูงสุด)

---

## Manual Setup (Linux/Ubuntu)

```bash
cd ragnarok-server
chmod +x setup.sh
./setup.sh
```

สคริปต์จะ:
1. ติดตั้ง dependencies (gcc, mariadb, ฯลฯ)
2. Clone rAthena จาก GitHub
3. Patch source code สำหรับ level 275
4. Compile server
5. ตั้งค่า database
6. Import SQL schema

---

## การตั้งค่า Client

1. แก้ไข `clientinfo.xml` ในโฟลเดอร์ client ให้ชี้ไป:
   ```xml
   <address>127.0.0.1</address>
   <port>6900</port>
   ```

2. ใช้ client version **2023-12-20** หรือใหม่กว่า (รองรับ 4th jobs)

3. Recommended client patcher: [NEMO](https://github.com/llchrisll/NEMO)

---

## Server Specs

| Setting         | Value   |
|-----------------|---------|
| Episode         | 21      |
| Max Base Level  | 275     |
| Max Job Level   | 60      |
| Mode            | Renewal |
| 4th Jobs        | Yes     |
| Base EXP Rate   | 1x      |
| Job EXP Rate    | 1x      |

---

## การปรับค่าเพิ่มเติม

### เพิ่ม EXP Rate
แก้ไข `conf/battle/exp.conf`:
```
base_exp_rate: 500   // 5x
job_exp_rate: 500    // 5x
```

### เปลี่ยนจุด spawn เริ่มต้น
แก้ไข `conf/char_athena.conf`:
```
start_point: prontera,155,183
```

### Restart server (Docker)
```bash
docker compose restart rathena
```

### ดู logs
```bash
docker compose logs -f rathena
```

### หยุด server
```bash
docker compose down
```

---

## โครงสร้างไฟล์

```
ragnarok-server/
├── docker-compose.yml      # Docker orchestration
├── Dockerfile              # rAthena build & runtime
├── entrypoint.sh           # Container startup script
├── setup.sh                # Manual setup script
└── conf/
    ├── inter_athena.conf   # Database connection
    ├── login_athena.conf   # Login server
    ├── char_athena.conf    # Char server + server name
    ├── map_athena.conf     # Map server
    └── battle/
        ├── player.conf     # Level limits (275/60)
        ├── exp.conf        # EXP rates
        └── misc.conf       # Misc settings
```
