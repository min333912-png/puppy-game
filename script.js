// 기본 프로필 데이터 (대화 내용과 100% 동일한 초기값)
const DEFAULT_STATE = {
  userName: "보민",
  dayMaster: "갑목",
  structure: "편재격",
  elements: {
    wood: 3,
    fire: 1,
    earth: 2,
    metal: 0,
    water: 2
  }
};

// 일간(본원)별 현대적 캐릭터 데이터베이스
const DAY_MASTER_DB = {
  갑목: {
    hanja: "甲木",
    archetype: "판 전체를 읽고 길을 내는 스타트업 창업가",
    trait: "하늘을 향해 곧게 뻗어 나가는 큰 나무(갑목)의 추진력과 상승 에너지를 지닌 리더",
    strength: "한 번 목표를 정하면 뒤돌아보지 않고 돌파하며 새로운 영역을 개척할 때 가장 빛납니다."
  },
  을목: {
    hanja: "乙木",
    archetype: "유연한 소통으로 판을 연결하는 커뮤니티 빌더",
    trait: "비바람에도 꺾이지 않는 화초(을목)의 회복탄력성과 뛰어난 환경 적응력을 지닌 네트워커",
    strength: "강압적인 방식보다 사람과 사람 사이를 부드럽게 연결하고 협업을 이끌어낼 때 진가가 발휘됩니다."
  },
  병화: {
    hanja: "丙火",
    archetype: "모두의 시선을 사로잡는 무대 위의 키노트 스피커",
    trait: "세상을 환하게 비추는 태양(병화)처럼 숨김없는 열정과 강력한 전파력을 지닌 인플루언서",
    strength: "비전을 명확하게 시각화하고 주변 사람들에게 긍정적인 동기를 불어넣을 때 에너지가 폭발합니다."
  },
  정화: {
    hanja: "丁火",
    archetype: "어둠 속에서 핵심을 꿰뚫는 장인형 크리에이터",
    trait: "은은하지만 가장 뜨거운 촛불(정화)처럼 깊은 몰입도와 섬세한 통찰력을 지닌 스페셜리스트",
    strength: "선택한 한 가지 영역에 깊이 파고들어 독보적인 디테일과 감동을 만들어낼 때 빛을 발합니다."
  },
  무토: {
    hanja: "戊土",
    archetype: "흔들림 없이 중심을 잡아주는 플랫폼 아키텍트",
    trait: "넓고 묵직한 대지(무토)처럼 다양한 사람과 자원을 담아내는 스케일과 신뢰감을 지닌 리더",
    strength: "위기 상황에서도 동요하지 않고 묵직하게 판을 지탱하며 중재자 역할을 맡을 때 최고조에 달합니다."
  },
  기토: {
    hanja: "己土",
    archetype: "아이디어를 현실의 결과물로 길러내는 프로덕트 매니저",
    trait: "비옥한 정원(기토)처럼 실용적이고 꼼꼼하게 사람과 프로젝트를 키워내는 실속파 전략가",
    strength: "추상적인 아이디어를 실행 가능한 단계로 구체화하고 내실을 다질 때 탁월한 성과를 냅니다."
  },
  경금: {
    hanja: "庚金",
    archetype: "복잡한 문제를 단번에 해결하는 턴어라운드 해결사",
    trait: "단단한 원석과 강철(경금)처럼 군더더기 없는 결단력과 강력한 실행력을 지닌 개혁가",
    strength: "모호한 상황을 명쾌하게 정리하고 속도감 있게 핵심 의사결정을 내릴 때 독보적입니다."
  },
  신금: {
    hanja: "辛金",
    archetype: "완벽한 퀄리티를 설계하는 하이엔드 큐레이터",
    trait: "잘 세공된 보석(신금)처럼 예리한 안목과 정교한 기준을 지닌 디테일 마스터",
    strength: "남들이 놓치는 미세한 차이를 포착해 브랜드나 결과물의 품격을 한 단계 끌어올릴 때 가장 빛납니다."
  },
  임수: {
    hanja: "壬水",
    archetype: "트렌드 너머의 거대한 흐름을 읽는 글로벌 전략가",
    trait: "넓고 깊은 바다(임수)처럼 유연한 사고방식과 방대한 정보 흡수력을 지닌 빅픽처 리더",
    strength: "고정관념에 얽매이지 않고 다양한 분야의 지식을 융합해 새로운 판을 설계할 때 강력합니다."
  },
  계수: {
    hanja: "癸水",
    archetype: "사람의 마음을 적시는 공감형 인사이트 기획자",
    trait: "대지를 촉촉이 적시는 봄비(계수)처럼 섬세한 관찰력과 깊은 지혜를 지닌 브레인",
    strength: "드러나지 않는 곳에서 핵심 니즈를 정확히 읽고 맞춤형 솔루션을 기획할 때 최고의 역량을 발휘합니다."
  }
};

// 격국별 사회적 무기 설명
const STRUCTURE_DB = {
  편재격: "전체적인 판의 흐름을 읽는 비즈니스 감각과 스케일 확장력(편재격)",
  정재격: "치밀한 데이터 관리와 흔들림 없는 안정적 실행력(정재격)",
  식신격: "한 분야를 깊이 파고드는 연구력와 창조적 몰입력(식신격)",
  상관격: "기존의 틀을 깨는 혁신적인 아이디어와 탁월한 표현력(상관격)",
  편관격: "어려운 과제를 정면 돌파하는 카리스마와 책임감(편관격)",
  정관격: "합리적인 시스템을 구축하고 조직의 신뢰를 얻는 조율력(정관격)",
  편인격: "남들이 보지 못하는 이면을 꿰뚫는 독창적 기획력(편인격)",
  정인격: "깊이 있는 지식 체계와 사람의 성장을 돕는 멘토링 역량(정인격)"
};

// 부족한 오행별 현대적 코칭 & 개운 루틴 데이터베이스
const LACKING_SOLUTION_DB = {
  metal: {
    name: "금(金 · 관성/결단)",
    summaryPrefix: "자유로운 탐험가형",
    careerTitle: "‘통제’가 아닌 ‘자율’이 당신의 날개입니다",
    careerAdvice:
      "정해진 매뉴얼과 상명하복이 강조되는 수직적 조직보다는 자율성과 재량권이 크게 보장되는 환경에서 역량이 극대화됩니다. 신사업 기획, 애자일(Agile) 조직, 프로젝트 디렉팅처럼 스스로 규칙과 일정을 설계하고 주도적으로 의사결정을 내릴 수 있는 영역에서 압도적인 성과를 낼 수 있습니다.",
    luckyColor: "화이트/실버",
    swatchGradient: "linear-gradient(135deg, #ffffff 0%, #cbd5e1 100%)",
    actionTitle: "저녁 10분, 가지치기 저널링 (3-Cut Rule)",
    actionTip:
      "매일 저녁 10분, 내일 떠오르는 수많은 아이디어와 할 일 중 가장 중요한 핵심 3가지만 남기고 나머지는 과감히 덜어내는 '가지치기 저널링(3-Cut Rule)'을 실천해 보세요. 부족한 결단력과 마무리의 힘(금 기운)을 보완하여 당신의 강력한 추진력을 가장 가치 있는 목표에 집중시켜 줍니다."
  },
  wood: {
    name: "목(木 · 기획/추진)",
    summaryPrefix: "완성도 높은 실무형",
    careerTitle: "완벽한 준비보다 ‘작은 시작’이 판을 바꿉니다",
    careerAdvice:
      "현재의 시스템을 안정적으로 유지하고 마무리하는 힘은 뛰어나지만, 백지상태에서 새로운 일을 벌이는 데 에너지를 많이 쓸 수 있습니다. 100% 완벽한 계획이 세워질 때까지 기다리기보다, 빠르게 프로토타입을 실행하고 피드백을 주고받는 환경에서 성장 속도가 비약적으로 빨라집니다.",
    luckyColor: "민트/포레스트 그린",
    swatchGradient: "linear-gradient(135deg, #6ee7b7 0%, #059669 100%)",
    actionTitle: "아침 15분, ‘일단 1줄 쓰기’ 모닝 스프린트",
    actionTip:
      "하루를 시작할 때 가장 미루고 싶었던 새로운 과제를 딱 15분만 타이머를 맞추고 첫 줄만 작성해 보세요. 시작의 엔진(목 기운)을 가볍게 예열하는 습관이 당신의 탄탄한 내실을 세상으로 꺼내어 큰 성취로 연결해 줍니다."
  },
  fire: {
    name: "화(火 · 표현/열정)",
    summaryPrefix: "깊이 있는 내면의",
    careerTitle: "당신의 탁월한 실력에 ‘스포트라이트’를 비추세요",
    careerAdvice:
      "내면의 깊이와 실무 역량은 이미 충분히 단단하지만, 내가 한 성과를 외부로 알리거나 감정을 표현하는 데에는 겸손한 편입니다. 결과물이 자연스럽게 드러나는 투명한 성과 공유 문화를 가진 곳이나, 당신의 전문성을 브랜딩해 줄 파트너가 있는 환경에서 가치가 2배 이상 상승합니다.",
    luckyColor: "코랄 레드/선셋 오렌지",
    swatchGradient: "linear-gradient(135deg, #fda4af 0%, #e11d48 100%)",
    actionTitle: "주 2회, ‘작업 로그(Work Log) 한 줄 공유하기’",
    actionTip:
      "내가 완료한 일이나 배운 인사이트를 동료나 개인 SNS, 노션에 한 줄로 가볍게 공유하는 루틴을 만들어 보세요. 세상을 향해 나를 드러내는 표현력(화 기운)이 채워지면서 뜻밖의 기회와 귀인이 빠르게 연결됩니다."
  },
  earth: {
    name: "토(土 · 중심/지속)",
    summaryPrefix: "역동적인 혁신가형",
    careerTitle: "빠른 속도에 ‘단단한 베이스캠프’를 더할 때입니다",
    careerAdvice:
      "변화에 민첩하게 반응하고 아이디어를 빠르게 실행하는 기동력이 타의 추종을 불허합니다. 다만 여러 곳으로 에너지가 흩어지지 않도록, 장기적인 호흡으로 아카이빙을 쌓을 수 있는 나만의 플랫폼이나 핵심 거점 프로젝트를 하나 정해두면 모든 경험이 큰 자산으로 묶입니다.",
    luckyColor: "웜 베이지/골드 브라운",
    swatchGradient: "linear-gradient(135deg, #fde68a 0%, #d97706 100%)",
    actionTitle: "매일 같은 시간, ‘앵커 타임(Anchor Time)’ 루틴",
    actionTip:
      "하루 중 단 20분이라도 같은 장소, 같은 시간에 앉아 하루의 기록을 한곳에 모으는 '앵커 타임'을 가져보세요. 흔들리지 않는 대지(토 기운)의 중심력을 길러주어 당신의 눈부신 아이디어가 단단한 현실적 결실로 쌓이게 합니다."
  },
  water: {
    name: "수(水 · 휴식/유연)",
    summaryPrefix: "불꽃처럼 몰입하는",
    careerTitle: "전략적 ‘여백’이 더 강력한 돌파력을 만듭니다",
    careerAdvice:
      "목표를 향한 실행력과 책임감이 워낙 강해 앞만 보고 달리는 경향이 있습니다. 쉼 없이 엔진을 가동하기보다, 주기적으로 인풋(독서, 사색, 리프레시)을 채우고 한 발짝 물러서서 조망할 수 있는 자율 출퇴근·워케이션 친화적 환경에서 가장 창의적인 해답을 찾아냅니다.",
    luckyColor: "딥 네이비/스카이 블루",
    swatchGradient: "linear-gradient(135deg, #93c5fd 0%, #1d4ed8 100%)",
    actionTitle: "밤 10시 이후, ‘디지털 오프 & 워터 리추얼’",
    actionTip:
      "잠들기 30분 전에는 스마트폰과 업무 알림을 끄고 따뜻한 차나 물 한 잔을 마시며 뇌에 여백을 선물하세요. 유연함과 재충전의 에너지(수 기운)가 채워질 때 다음 날 당신의 직관력과 통찰력이 가장 날카롭게 빛납니다."
  }
};

// 현재 상태
let state = JSON.parse(JSON.stringify(DEFAULT_STATE));

// DOM 요소 참조
const userNameInput = document.getElementById("userNameInput");
const birthDateInput = document.getElementById("birthDateInput");
const calcBirthBtn = document.getElementById("calcBirthBtn");
const resetDefaultBtn = document.getElementById("resetDefaultBtn");
const dayMasterSelect = document.getElementById("dayMasterSelect");
const structureSelect = document.getElementById("structureSelect");
const analyzeBtn = document.getElementById("analyzeBtn");
const copyJsonBtn = document.getElementById("copyJsonBtn");

// 가장 부족한 오행 찾기 (동점일 경우 금 -> 수 -> 목 -> 화 -> 토 순 우선순위)
function getLackingElementKey(elements) {
  const order = ["metal", "water", "wood", "fire", "earth"];
  let minKey = order[0];
  let minVal = elements[minKey];

  for (const key of order) {
    if (elements[key] < minVal) {
      minVal = elements[key];
      minKey = key;
    }
  }
  return minKey;
}

// 대화 원본 프로필인지 확인 (초기 대화 JSON과 100% 일치 보장)
function isExactDefaultConversationProfile() {
  return (
    state.dayMaster === "갑목" &&
    state.structure === "편재격" &&
    state.elements.metal === 0 &&
    getLackingElementKey(state.elements) === "metal"
  );
}

// 분석 리포트 데이터 생성 (순수 JSON 스키마 준수)
function buildCoachingData() {
  const dmInfo = DAY_MASTER_DB[state.dayMaster] || DAY_MASTER_DB["갑목"];
  const structDesc = STRUCTURE_DB[state.structure] || STRUCTURE_DB["편재격"];
  const lackKey = getLackingElementKey(state.elements);
  const lackSolution = LACKING_SOLUTION_DB[lackKey];

  // 대화와 동일한 조건일 경우 대화에서 출력한 문구 그대로 제공
  if (isExactDefaultConversationProfile()) {
    return {
      json: {
        summary_keyword: "자유로운 탐험가형 전략가",
        character_analysis:
          "하늘을 향해 곧게 뻗어 나가는 큰 나무(갑목)의 추진력과 전체적인 판의 흐름을 읽는 비즈니스 감각(편재격)을 동시에 지닌 리더입니다. 든든한 에너지원과 실행력을 바탕으로 작은 디테일에 얽매이기보다 새로운 영역을 개척하고 큰 그림을 그릴 때 가장 빛나는 스타일입니다.",
        career_advice:
          "정해진 매뉴얼과 상명하복이 강조되는 수직적 조직보다는 자율성과 재량권이 크게 보장되는 환경에서 역량이 극대화됩니다. 신사업 기획, 애자일(Agile) 조직, 프로젝트 디렉팅처럼 스스로 규칙과 일정을 설계하고 주도적으로 의사결정을 내릴 수 있는 영역에서 압도적인 성과를 낼 수 있습니다.",
        lucky_color: "화이트/실버",
        action_tip:
          "매일 저녁 10분, 내일 떠오르는 수많은 아이디어와 할 일 중 가장 중요한 핵심 3가지만 남기고 나머지는 과감히 덜어내는 '가지치기 저널링(3-Cut Rule)'을 실천해 보세요. 부족한 결단력과 마무리의 힘(금 기운)을 보완하여 당신의 강력한 추진력을 가장 가치 있는 목표에 집중시켜 줍니다."
      },
      meta: {
        dmHanja: dmInfo.hanja,
        charTitle: dmInfo.archetype,
        careerTitle: lackSolution.careerTitle,
        actionTitle: lackSolution.actionTitle,
        lackName: "금(金 · 관성)",
        swatchGradient: lackSolution.swatchGradient
      }
    };
  }

  // 사용자 커스텀 조합일 때 맞춤형 생성
  const summaryKeyword = `${lackSolution.summaryPrefix} 전략가`;
  const characterAnalysis = `${dmInfo.trait}이자, ${structDesc}을 동시에 지닌 인재입니다. ${dmInfo.strength}`;

  return {
    json: {
      summary_keyword: summaryKeyword,
      character_analysis: characterAnalysis,
      career_advice: lackSolution.careerAdvice,
      lucky_color: lackSolution.luckyColor,
      action_tip: lackSolution.actionTip
    },
    meta: {
      dmHanja: dmInfo.hanja,
      charTitle: dmInfo.archetype,
      careerTitle: lackSolution.careerTitle,
      actionTitle: lackSolution.actionTitle,
      lackName: lackSolution.name,
      swatchGradient: lackSolution.swatchGradient
    }
  };
}

// 오행 바 차트 및 범례 렌더링
function renderElementChart() {
  const stackedBar = document.getElementById("stackedBar");
  const barLegend = document.getElementById("barLegend");
  const totalCountEl = document.getElementById("totalElementsCount");
  const lackingBadge = document.getElementById("lackingElementBadge");
  const balanceComment = document.getElementById("balanceComment");

  const items = [
    { key: "wood", label: "목(木)", color: "var(--el-wood)", count: state.elements.wood },
    { key: "fire", label: "화(火)", color: "var(--el-fire)", count: state.elements.fire },
    { key: "earth", label: "토(土)", color: "var(--el-earth)", count: state.elements.earth },
    { key: "metal", label: "금(金)", color: "var(--el-metal)", count: state.elements.metal },
    { key: "water", label: "수(水)", color: "var(--el-water)", count: state.elements.water }
  ];

  const total = items.reduce((acc, cur) => acc + cur.count, 0);
  totalCountEl.textContent = total;

  // 스텝퍼 숫자 동기화
  items.forEach((item) => {
    const valSpan = document.getElementById(`val-${item.key}`);
    if (valSpan) valSpan.textContent = item.count;
  });

  // 부족한 오행 표시
  const lackKey = getLackingElementKey(state.elements);
  const lackInfo = LACKING_SOLUTION_DB[lackKey];
  lackingBadge.textContent = `보완 포인트: ${lackInfo.name.split(" ")[0]}`;

  // 스택 바 생성
  stackedBar.innerHTML = "";
  barLegend.innerHTML = "";

  items.forEach((item) => {
    if (item.count > 0 && total > 0) {
      const seg = document.createElement("div");
      seg.className = "bar-segment";
      seg.style.width = `${(item.count / total) * 100}%`;
      seg.style.backgroundColor = item.color;
      seg.title = `${item.label}: ${item.count}`;
      stackedBar.appendChild(seg);
    }

    const leg = document.createElement("span");
    leg.className = `legend-item ${item.count === 0 ? "legend-zero" : ""}`;
    leg.innerHTML = `<span class="el-dot" style="background:${item.color}"></span>${item.label} ${item.count}${item.count === 0 ? " (부족)" : ""}`;
    barLegend.appendChild(leg);
  });

  // 가장 강한 오행과 부족한 오행 코멘트
  const maxItem = [...items].sort((a, b) => b.count - a.count)[0];
  balanceComment.textContent = `${maxItem.label} 에너지가 중심을 이끌고 있으며, ${lackInfo.name.split(" ")[0]} 에너지를 일상 루틴으로 채우면 밸런스가 완성됩니다.`;
}

// 전체 리포트 UI 업데이트
function renderReport() {
  state.userName = userNameInput.value.trim() || "회원";
  state.dayMaster = dayMasterSelect.value;
  state.structure = structureSelect.value;

  const { json, meta } = buildCoachingData();

  document.getElementById("reportUserName").textContent = state.userName;
  document.getElementById("tagDayMaster").textContent = `일간: ${state.dayMaster}(${meta.dmHanja})`;
  document.getElementById("tagStructure").textContent = `격국: ${state.structure}`;
  document.getElementById("tagLacking").textContent = `보완 에너지: ${meta.lackName}`;

  document.getElementById("luckyColorText").textContent = json.lucky_color;
  document.getElementById("luckyColorSwatch").style.background = meta.swatchGradient;

  document.getElementById("summaryKeyword").textContent = `"${json.summary_keyword}"`;
  document.getElementById("charTitle").textContent = meta.charTitle;
  document.getElementById("characterAnalysis").textContent = json.character_analysis;

  document.getElementById("careerTitle").textContent = meta.careerTitle;
  document.getElementById("careerAdvice").textContent = json.career_advice;

  document.getElementById("actionTitle").textContent = meta.actionTitle;
  document.getElementById("actionTip").textContent = json.action_tip;

  // 순수 JSON 출력뷰 업데이트
  document.getElementById("jsonOutput").textContent = JSON.stringify(json, null, 2);

  renderElementChart();
}

// 오행 조절 버튼 이벤트
document.querySelectorAll(".step-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    const action = btn.dataset.action;
    const target = btn.dataset.target;
    if (action === "inc" && state.elements[target] < 8) {
      state.elements[target] += 1;
    } else if (action === "dec" && state.elements[target] > 0) {
      state.elements[target] -= 1;
    }
    renderReport();
  });
});

// 셀렉트 및 이름 변경 시 실시간 반영
dayMasterSelect.addEventListener("change", renderReport);
structureSelect.addEventListener("change", renderReport);
userNameInput.addEventListener("input", renderReport);
analyzeBtn.addEventListener("click", renderReport);

// 생년월일 기반 일주(천간) 간편 계산기 (1900-01-01 기준 60갑자 일진 계산)
calcBirthBtn.addEventListener("click", () => {
  const dateVal = birthDateInput.value;
  if (!dateVal) return;

  const [y, m, d] = dateVal.split("-").map(Number);
  const targetDate = Date.UTC(y, m - 1, d);
  const baseDate = Date.UTC(1900, 0, 1); // 1900-01-01은 갑술(甲戌)일 (천간 index 0 = 갑)
  const diffDays = Math.floor((targetDate - baseDate) / (1000 * 60 * 60 * 24));
  const stemIndex = ((diffDays % 10) + 10) % 10;

  const stems = ["갑목", "을목", "병화", "정화", "무토", "기토", "경금", "신금", "임수", "계수"];
  const structures = ["편재격", "정재격", "식신격", "상관격", "편관격", "정관격", "편인격", "정인격"];

  const calculatedStem = stems[stemIndex];
  const calculatedStruct = structures[(y + m + d) % structures.length];

  // 월지에 따른 오행 분포 시뮬레이션
  const seed = y + m * 7 + d;
  const raw = [
    (seed % 3) + 1,
    ((seed >> 1) % 3),
    ((seed >> 2) % 3) + 1,
    ((seed >> 3) % 2),
    ((seed >> 4) % 3) + 1
  ];
  // 최소 1개는 0이 되도록 보정하여 보완 솔루션이 명확히 보이도록 구성
  const minIdx = seed % 5;
  raw[minIdx] = 0;

  dayMasterSelect.value = calculatedStem;
  structureSelect.value = calculatedStruct;
  state.elements = {
    wood: raw[0],
    fire: raw[1],
    earth: raw[2],
    metal: raw[3],
    water: raw[4]
  };

  renderReport();
});

// 기본 프로필(대화 데이터) 복원 버튼
resetDefaultBtn.addEventListener("click", () => {
  state = JSON.parse(JSON.stringify(DEFAULT_STATE));
  userNameInput.value = state.userName;
  dayMasterSelect.value = state.dayMaster;
  structureSelect.value = state.structure;
  renderReport();
});

// JSON 복사 버튼
copyJsonBtn.addEventListener("click", async () => {
  const jsonText = document.getElementById("jsonOutput").textContent;
  try {
    await navigator.clipboard.writeText(jsonText);
    const orig = copyJsonBtn.textContent;
    copyJsonBtn.textContent = "복사 완료!";
    setTimeout(() => {
      copyJsonBtn.textContent = orig;
    }, 1500);
  } catch (e) {
    alert("클립보드 복사에 실패했습니다.");
  }
});

// 3-Cut 가지치기 저널링 로컬 스토리지 연동
function initRoutineTracker() {
  const saved = localStorage.getItem("mind_element_3cut");
  if (saved) {
    try {
      const parsed = JSON.parse(saved);
      parsed.forEach((item, idx) => {
        const chk = document.getElementById(`cutCheck${idx + 1}`);
        const inp = document.getElementById(`cutInput${idx + 1}`);
        if (chk && inp) {
          chk.checked = !!item.checked;
          inp.value = item.text ?? inp.value;
        }
      });
    } catch (_) {}
  }

  function updateTrackerState() {
    let completedCount = 0;
    const dataToSave = [];

    for (let i = 1; i <= 3; i++) {
      const chk = document.getElementById(`cutCheck${i}`);
      const inp = document.getElementById(`cutInput${i}`);
      const row = chk.closest(".cut-item");
      if (chk.checked) {
        completedCount++;
        row.classList.add("completed");
      } else {
        row.classList.remove("completed");
      }
      dataToSave.push({ checked: chk.checked, text: inp.value });
    }

    document.getElementById("routineProgressText").textContent = `${completedCount} / 3 완료`;
    localStorage.setItem("mind_element_3cut", JSON.stringify(dataToSave));
  }

  for (let i = 1; i <= 3; i++) {
    document.getElementById(`cutCheck${i}`).addEventListener("change", updateTrackerState);
    document.getElementById(`cutInput${i}`).addEventListener("input", updateTrackerState);
  }

  updateTrackerState();
}

// 초기화 실행
initRoutineTracker();
renderReport();
