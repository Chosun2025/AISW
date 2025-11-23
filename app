import streamlit as st
import pandas as pd
import os

# -----------------------------
# 🔧 기본 설정
# -----------------------------
st.set_page_config(page_title="팀 프로젝트 온라인 전시관", layout="wide")
st.title("🎉 팀 프로젝트 온라인 전시관 (Online Gallery) 🎉")
st.caption("✨ 분반별로 멋진 프로젝트들을 구경해 보세요! ✨")

# 🔐 교수용 관리자 비밀번호 (실사용 시 st.secrets 권장)
ADMIN_PASSWORD = "prof1234"

# 📂 데이터/파일 경로
TEAM_FILE = "team_info.csv"         # 분반/팀별 결과물 데이터
UPLOAD_DIR = "uploads"              # PPT PDF 저장 폴더
os.makedirs(UPLOAD_DIR, exist_ok=True)

# -----------------------------
# 1. 분반 & 팀 목록
# -----------------------------
sections = ["분반1", "분반2", "분반3", "분반4"]        # 4개 분반
teams = [f"팀{i}" for i in range(1, 29)]              # 팀1 ~ 팀28

# -----------------------------
# 2. 팀 정보 로드 & 저장 함수
# -----------------------------
def load_team_info():
    """분반/팀별 결과물 데이터 로드 (Streamlit 링크 + PPT 파일 경로)"""
    required_cols = ["section", "team", "site_url", "ppt_file"]
    if os.path.exists(TEAM_FILE):
        df = pd.read_csv(TEAM_FILE)
        for col in required_cols:
            if col not in df.columns:
                df[col] = ""
        return df[required_cols]
    else:
        return pd.DataFrame(columns=required_cols)


def save_team_info(df: pd.DataFrame):
    """분반/팀별 결과물 데이터 저장"""
    df.to_csv(TEAM_FILE, index=False)


# -----------------------------
# 3. 사이드바: 모드 선택
# -----------------------------
mode = st.sidebar.radio(
    "🧭 모드 선택",
    ["🖼 온라인 전시관", "🛠 교수용 관리"]
)

# ============================================================
# 🖼  모드 1: 온라인 전시관 (학생·관객용)
# ============================================================
if mode.startswith("🖼"):
    st.subheader("🖼 온라인 전시관")
    st.markdown("각 팀의 **Streamlit 앱**과 **PPT PDF**를 카드 형식으로 전시합니다 💫")

    # 분반 필터 (전체 포함)
    section_filter = st.radio(
        "📚 보고 싶은 분반을 선택하세요",
        ["전체 분반 ✨"] + sections,
        horizontal=True,
    )

    team_df = load_team_info()

    if team_df.empty:
        st.info("아직 등록된 결과물이 없습니다. 교수님이 관리 페이지에서 등록하면 이곳에 전시됩니다 🧩")
    else:
        # 필터 적용
        if section_filter == "전체 분반 ✨":
            df_show = team_df.copy()
        else:
            df_show = team_df[team_df["section"] == section_filter].copy()

        # 정렬 (분반, 팀 순)
        df_show["team_num"] = df_show["team"].str.replace("팀", "").astype(int)
        df_show = df_show.sort_values(by=["section", "team_num"])

        st.write("")  # 약간의 여백

        # 🎨 갤러리 레이아웃: 가로 3열 카드
        cols_per_row = 3
        cards = list(df_show.itertuples(index=False))

        if not cards:
            st.info("선택한 분반에 아직 등록된 결과물이 없습니다 💤")
        else:
            for row_start in range(0, len(cards), cols_per_row):
                row_cards = cards[row_start:row_start + cols_per_row]
                cols = st.columns(len(row_cards))

                for col, item in zip(cols, row_cards):
                    section = item.section
                    team = item.team
                    site_url = str(item.site_url) if isinstance(item.site_url, str) else ""
                    ppt_file = str(item.ppt_file) if isinstance(item.ppt_file, str) else ""

                    with col:
                        # 카드 박스 스타일용 컨테이너
                        with st.container():
                            st.markdown(
                                f"""
                                <div style="
                                    border-radius: 16px;
                                    padding: 16px;
                                    margin-bottom: 8px;
                                    background: linear-gradient(135deg, #fdfbfb 0%, #ebedee 100%);
                                    box-shadow: 0 4px 10px rgba(0,0,0,0.05);
                                ">
                                    <h4 style="margin-bottom:4px;">🎯 {section} · {team}</h4>
                                    <p style="margin-top:0; margin-bottom:10px; font-size:0.9rem;">
                                        📌 팀 프로젝트 작품<br>
                                        <span style="font-size:0.8rem; color:#666;">(클릭해서 자세히 보기)</span>
                                    </p>
                                </div>
                                """,
                                unsafe_allow_html=True,
                            )

                            # 버튼들
                            if site_url.strip():
                                st.link_button("🌐 Streamlit 앱 열기", site_url, use_container_width=True)
                            else:
                                st.button("🚫 Streamlit 링크 없음", disabled=True, use_container_width=True)

                            if ppt_file and os.path.exists(ppt_file):
                                with open(ppt_file, "rb") as f:
                                    pdf_bytes = f.read()
                                st.download_button(
                                    label="📥 PPT PDF 다운로드",
                                    data=pdf_bytes,
                                    file_name=os.path.basename(ppt_file),
                                    mime="application/pdf",
                                    key=f"download_gallery_{section}_{team}",
                                    use_container_width=True,
                                )
                            else:
                                st.button("📄 PPT PDF 미등록", disabled=True, use_container_width=True)

                            # 귀여운 한 줄 멘트
                            st.markdown(
                                "<p style='text-align:center; font-size:0.8rem;'>💡 멋진 아이디어와 노력에 박수를! 👏</p>",
                                unsafe_allow_html=True,
                            )


# ============================================================
# 🛠  모드 2: 교수용 관리 페이지
# ============================================================
elif mode.startswith("🛠"):
    st.subheader("🛠 교수용 관리 페이지")
    st.markdown("분반·팀별 **Streamlit 링크 등록**과 **PPT PDF 업로드**를 할 수 있습니다.")

    password = st.text_input("🔑 관리자 비밀번호를 입력하세요", type="password")

    if password != ADMIN_PASSWORD and password != "":
        st.error("비밀번호가 올바르지 않습니다 😢")

    if password == ADMIN_PASSWORD:
        st.success("관리자 모드로 접속되었습니다 ✅")

        team_df = load_team_info()

        # --------------------------------
        # (1) PPT PDF 업로드
        # --------------------------------
        st.write("---")
        st.markdown("### 📥 분반/팀별 PPT PDF 파일 업로드")

        upload_sec = st.selectbox("📚 분반 선택", sections, key="pdf_section")
        upload_team = st.selectbox("🧩 팀 선택", teams, key="pdf_team")

        uploaded_pdf = st.file_uploader(
            "이 팀의 발표자료 PDF 파일을 업로드하세요",
            type=["pdf"],
            key="pdf_uploader"
        )

        if uploaded_pdf is not None:
            filename = f"{upload_sec}_{upload_team}_{uploaded_pdf.name}"
            file_path = os.path.join(UPLOAD_DIR, filename)

            with open(file_path, "wb") as f:
                f.write(uploaded_pdf.getbuffer())

            df = load_team_info()
            mask = (df["section"] == upload_sec) & (df["team"] == upload_team)
            if df.empty or not mask.any():
                new_row = {
                    "section": upload_sec,
                    "team": upload_team,
                    "site_url": "",
                    "ppt_file": file_path,
                }
                df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
            else:
                df.loc[mask, "ppt_file"] = file_path

            save_team_info(df)
            st.success(f"✅ {upload_sec} - {upload_team} 팀의 PPT PDF가 업로드되었습니다.")

        # --------------------------------
        # (2) Streamlit 링크 등록/수정
        # --------------------------------
        st.write("---")
        st.markdown("### 🌐 분반/팀별 Streamlit 링크 등록/수정")

        team_df = load_team_info()
        existing_map = {}
        if not team_df.empty:
            for _, row in team_df.iterrows():
                key = (row["section"], row["team"])
                existing_map[key] = {
                    "site_url": str(row["site_url"]) if isinstance(row["site_url"], str) else "",
                    "ppt_file": str(row["ppt_file"]) if isinstance(row["ppt_file"], str) else "",
                }

        selected_section_for_url = st.selectbox("링크를 관리할 분반 선택", sections, key="url_section")

        rows = []
        st.markdown(f"#### ✏️ {selected_section_for_url} 팀별 Streamlit URL 입력")

        for t in teams:
            key = (selected_section_for_url, t)
            existing_site = existing_map.get(key, {}).get("site_url", "")
            existing_ppt_file = existing_map.get(key, {}).get("ppt_file", "")

            site_url = st.text_input(
                f"{t} Streamlit URL",
                value=existing_site,
                key=f"site_{selected_section_for_url}_{t}",
                placeholder="https://team-app.streamlit.app/...",
            )

            rows.append({
                "section": selected_section_for_url,
                "team": t,
                "site_url": site_url,
                "ppt_file": existing_ppt_file,
            })

        if st.button("💾 현재 분반 링크 저장하기"):
            new_sec_df = pd.DataFrame(rows)

            if not team_df.empty:
                others = team_df[team_df["section"] != selected_section_for_url]
                final_df = pd.concat([others, new_sec_df], ignore_index=True)
            else:
                final_df = new_sec_df

            save_team_info(final_df)
            st.success(f"✅ {selected_section_for_url}의 팀별 Streamlit 링크가 저장되었습니다.")

        # --------------------------------
        # (3) 전체 팀 정보 확인
        # --------------------------------
        st.write("---")
        st.markdown("### 📋 현재 등록된 전체 팀 정보")

        current_team_df = load_team_info()
        if current_team_df.empty:
            st.info("아직 등록된 결과물 정보가 없습니다.")
        else:
            st.dataframe(current_team_df)
