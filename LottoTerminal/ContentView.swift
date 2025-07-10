//
//  ContentView.swift
//  LottoTerminal
//
//  Created by sorak azae on 7/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var scannedCode: String = ""
    @State private var showPopup: Bool = false
    @State private var resultMessage: String = ""
    
    var body: some View {
        ZStack {
            HStack {
                // 왼쪽 설명 영역
                VStack(alignment: .leading, spacing: 12) {
                    Text("로또 QR 스캔 안내")
                        .font(.title2)
                        .bold()
                    Text("1. QR 코드를 왼쪽 위의 모서리 뒷면에 있는 카메라에 비춰주세요.")
                    Text("2. 자동으로 인식되며 결과가 표시됩니다.")
                    Text("3. 매주 토요일 오후 8시 35분 경 추첨!")
                    
                    // 🔽 아래에 이미지 추가
                    Image("scan_guide") // 이미지 이름
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(minWidth: 350, maxWidth: 400) // 이미지 크기 조절
                        .cornerRadius(8)
                        .padding(.top, 16)
                    
                    Spacer()
                }
                .padding()
                .frame(minWidth: 350, maxWidth: 400) // 왼쪽 폭 제한
                .layoutPriority(1) // 우선배치

                // 오른쪽 카메라 영역
                CameraView(scannedCode: $scannedCode)
                    .onChange(of: scannedCode) { newCode in
                        if !newCode.isEmpty {
                            handleScanned(code: newCode)
                        }
                    }
                    .cornerRadius(10)
            }

            // QR 인식 시 팝업
            if showPopup {
                VStack(spacing: 16) {
                    Text("추첨결과")
                        .font(.title)
                        .bold()
                        .foregroundColor(.black)
                    Text(resultMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                    // 닫기 버튼 제거
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding()
            }
        }
    }
    
    
    func parseLottoQR(from url: String) -> (round: Int, games: [(type: String, numbers: [Int])])? {
        guard let components = URLComponents(string: url),
              let vParamRaw = components.queryItems?.first(where: { $0.name == "v" })?.value else {
            return nil
        }

        let vParam = vParamRaw.replacingOccurrences(of: ".net", with: "")

        guard let round = Int(vParam.prefix(4)) else { return nil }

        let pattern = #"[msq]\d+"# // ✅ m, s, q 모두 포함
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: vParam, range: NSRange(location: 0, length: vParam.utf16.count)) ?? []

        var games: [(String, [Int])] = []

        for match in matches {
            if let range = Range(match.range, in: vParam) {
                let block = String(vParam[range]) // 예: m253334404445
                let typeChar = block.prefix(1)
                let digits = block.dropFirst()

                var type = "?"
                switch typeChar {
                case "m": type = "수동"
                case "s": type = "반자동"
                case "q": type = "자동"
                default: break
                }

                var numbers: [Int] = []
                var idx = digits.startIndex

                for _ in 0..<6 {
                    let nextIdx = digits.index(idx, offsetBy: 2, limitedBy: digits.endIndex) ?? digits.endIndex
                    if idx >= digits.endIndex { break }

                    let numStr = digits[idx..<nextIdx]
                    if let num = Int(numStr) {
                        numbers.append(num)
                    }
                    idx = nextIdx
                }

                if numbers.count == 6 {
                    games.append((type, numbers.sorted()))
                }
            }
        }

        return (round, games)
    }

    func handleScanned(code: String) {
        // https://m.dhlottery.co.kr/qr.do?method=winQr&v=1125m152023263944m070827293643m161722303743m010821273639m2533344044450000000645.net
        guard let result = parseLottoQR(from: code) else {
            resultMessage = "QR 코드 파싱에 실패했습니다."
            showPopup = true
            return
        }

        let round = result.round
        let games = result.games

        // [API 호출] - 회차별 당첨번호 가져오기
        fetchLottoResult(for: round) { winning in
            guard let winning = winning else {
                resultMessage = "당첨 번호를 불러오는 데 실패했습니다."
                showPopup = true
                return
            }

            let winningNumbers = [
                winning.drwtNo1, winning.drwtNo2, winning.drwtNo3,
                winning.drwtNo4, winning.drwtNo5, winning.drwtNo6
            ]
            let bonus = winning.bnusNo

            let labels = ["A", "B", "C", "D", "E"]
            var messages: [String] = []

            for (index, game) in games.enumerated() {
                let (type, userNumbers) = game
                let matched = userNumbers.filter { winningNumbers.contains($0) }.count
                let hasBonus = userNumbers.contains(bonus)
                let label = index < labels.count ? labels[index] : "게임\(index+1)"

                let resultText: String
                switch matched {
                case 6: resultText = "🎉 1등 당첨! 로또센터 방문이 필요합니다."
                case 5: resultText = hasBonus ? "🎉 2등 당첨! 로또센터 방문이 필요합니다." : "축! 3등 당첨! 가까운 은행에서 수령 가능합니다."
                case 4: resultText = "축! 4등 당첨! 판매인에게 당첨금을 수령받으세요."
                case 3: resultText = "축! 5등 당첨! 판매인에게 당첨금을 수령받으세요."
                default: resultText = "낙첨입니다."
                }

                messages.append("\(label) [\(type)] - \(resultText)")
            }

            DispatchQueue.main.async {
                resultMessage = """
                \(round)회차 당첨 결과

                \(messages.joined(separator: "\n"))
                """
                showPopup = true
                
                // 5초 후 자동 닫기
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    // 만약 아직 같은 결과가 표시중이라면 닫음
                    if(showPopup) {
                        showPopup = false
                        scannedCode = "" // 다시 스캔 가능하게 초기화
                    }
                }
            }
        }
    }
    
}
