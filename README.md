เป็นตัวอย่างสำหรับ App ที่เสร็จสมบูรณ์ มีทั้ง Frontend-Backend การDevOps เเละ การ Deploy
-สำหรับการ DevOps ไฟล์ที่เกี่ยวข้องคือ .jenkinsfile
-สำหรับการ Deploy ไฟล์ที่เกี่ยวข้องคือ docker-compose.yml , Dockerfile เเละ URL ทั้งหมดจะถูกเปลี่ยน เช่น จาก Uri.parse('http://10.0.2.2:8000/token') กลายเป็น Uri.parse('http://54.169.248.246:8000/token') เป็นต้น

วิธีรันฝั่งblackend
1. cd backend
2. poetry shell
3. .\scripts\run-api  

วิธีรันฝั่งfrontend
1. ไปที่ไฟล์ main.dart ใน Folder lib
2. เปิด android emulator
3. ไปด้านบนทางขวา กด Run Without Debugging

วิธี clone
1. git clone
ในbackend
1. cd backend
2. pip install poetry
3. poetry install
4. poetry shell
5. docker run -d --name aroiwa-server -e POSTGRES_PASSWORD=123456 -p 5432:5432 postgres:16
6. docker run --name aroiwa-PGadmin -p 5050:80 -e PGADMIN_DEFAULT_EMAIL=6410110238@psu.ac.th -e PGADMIN_DEFAULT_PASSWORD=147896325 -d dpage/pgadmin4
7. .\scripts\run-api   
ในfrontend
1. cd .\frontend\aroiwa\
2. flutter pub get
