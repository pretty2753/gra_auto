async function checkWinner() {

	// 입력값 공백 제거(trim)
    const name = document.getElementById("name").value.trim();
    const receipt_no = document.getElementById("receipt_no").value.trim();

	// 빈값 체크(validation)
	if (!name || !receipt_no) {
        alert("이름과 접수번호를 입력해주세요.");
        return;
    }

	//길이 제한(validation)
    if (name.length > 100) {
        alert("이름은 100자 이하로 입력해주세요.");
        return;
    }

    if (receipt_no.length > 100) {
        alert("접수번호는 100자 이하로 입력해주세요.");
        return;
    }

    // // ================================
    // // 5. XSS 방어
    // // ================================
    // // HTML 태그 특수문자 치환
    // // <script> 공격 방지
    // const escapeHtml = (str) => {
    //     return str
    //         .replace(/&/g, "&amp;")
    //         .replace(/</g, "&lt;")
    //         .replace(/>/g, "&gt;")
    //         .replace(/"/g, "&quot;")
    //         .replace(/'/g, "&#039;");
    // };
    // name = escapeHtml(name);
    // receipt_no = escapeHtml(receipt_no);


	// 동기 조회(fetch API)
    const response = await fetch("/check", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            name: name,
            receipt_no: receipt_no
        })
    });

	// 응답 데이터 JSON 변환
    const data = await response.json();

	// 결과 출력 영역 가져오기
    const resultDiv = document.getElementById("result");

	// 조회 성공 시 화면 출력
    if (data.success) {	//성공
        resultDiv.innerHTML = `
            <h2>${data.result}</h2>
            <p>이름: ${data.name}</p>
            <p>접수번호: ${data.receipt_no}</p>
        `;
    } else { 			// 실패
        resultDiv.innerHTML = `
            <p style="color:red;">
                ${data.message}
            </p>
        `;
    }
}