# 🐶 해피 멍멍이 타운 (Happy Doggy Town) - Roblox & Supabase DB

**Antigravity AI (`agy`) + Roblox Studio MCP + Supabase PostgreSQL**을 활용하여 제작한 로블록스 3D 강아지 키우기 & 유기견 보호소 봉사 게임 프로젝트입니다.

---

## ✨ 주요 구현 기능

1. **🐕‍🦺 강아지 9종 & 최대 3마리 멀티 동행 시스템**
   - 기본 아기 강아지, 시바견(도지), 퍼그, 웰시코기, 시베리안 허스키, 저먼 셰퍼드, 골든 리트리버 + 랜덤 알 뽑기 전용 신화/전설 강아지(**✨황금 시바견**, **🌈네온 허스키**)
   - 보유한 강아지 중 코인 배율이 높은 상위 3마리가 자동으로 대열을 맞춰 플레이어를 따라다닙니다.
2. **🏇 리얼 강아지 라이딩 (`R`키 또는 하단 `[🏇 타기]` 버튼)**
   - `RideWeld` 물리 용접 + `HipHeight` 골반 높이 보정 + R15/R6 안장 탑승 다리 포즈 및 갤럽(Gallop) 바운스 애니메이션으로 강아지 등에 실제로 올라타 **이동속도 2배(WalkSpeed 36)**로 질주합니다.
3. **🏥 유기견 보호소 & 길 잃은 유기견 구조 봉사 시스템**
   - 보호소 3대 봉사 스테이션(특식 배식, 수의사 건강검진/치료, 견사 청소) + 마을 곳곳에 스폰되는 **길 잃은 유기견 구조**를 통해 봉사 코인과 **3회마다 특별 봉사 장학금(+120 코인)**을 획득합니다.
4. **✨ 오라 진화 / 👑 명예 브리더 승급(환생) / 🏡 마당 3단계 업그레이드 / 🏁 스피드 레이싱**
5. **⚡ Supabase PostgreSQL 클라우드 DB 연동**
   - **클라우드 세이브 (`player_profiles`)**: 코인, 레벨, 승급 횟수, 유기견 봉사 횟수, 보유 강아지/악세사리 자동 저장 및 불러오기
   - **글로벌 실시간 3대 랭킹 (`GlobalSupabaseBoard`)**: 최고 부자 TOP 5, 유기견 봉사 영웅 TOP 5, 스피드 레이싱 최단 기록 TOP 5
   - **전 세계 유기견 보호소 누적 구조 캠페인 (`global_shelter_stats` & `record_shelter_activity` RPC)**
   - **실시간 프로모션 쿠폰 (`promo_codes` & `code_redemptions`)**: `HAPPYDOG2026`, `SHELTERHERO`, `SUPABASE`

---

## 📂 파일 구성

| 파일명 | 설명 |
| :--- | :--- |
| [`오늘의_수업_복습노트.md`](./오늘의_수업_복습노트.md) | 오늘 배운 모든 개념과 생소한 용어(MCP, Luau, RemoteEvent, Weld, Supabase, SQL, Upsert, RPC 등)를 비유로 쉽게 정리한 복습 노트 |
| [`supabase_schema.sql`](./supabase_schema.sql) | Supabase SQL Editor에 붙여넣어 실행하는 PostgreSQL 테이블·인덱스·RLS·RPC 함수 전체 스키마 |
| [`SupabaseService.luau`](./SupabaseService.luau) | 로블록스 `ServerScriptService.SupabaseService` 모듈 스크립트 (REST API 연동 + 하이브리드 로컬 캐시 내장) |
| [`DogGameServer.luau`](./DogGameServer.luau) | 로블록스 `ServerScriptService.DogGameServer` 메인 서버 스크립트 |
| [`DogGameClient.luau`](./DogGameClient.luau) | 로블록스 `StarterPlayer.StarterPlayerScripts.DogGameClient` 클라이언트 UI & 라이딩 애니메이션 스크립트 |
