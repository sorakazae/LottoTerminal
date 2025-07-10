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
                    Text("1. QR 코드를 화면 오른쪽에 비춰주세요.")
                    Text("2. 자동으로 인식되며 결과가 표시됩니다.")
                    Text("3. 매주 토요일 오후 8시 35분 경 추첨!")
                    Spacer()
                }
                .padding()
                .frame(maxWidth: 300) // 왼쪽 폭 제한

                // 오른쪽 카메라
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
                    Text("🎉 인식 완료!")
                        .font(.title)
                        .bold()
                    Text(resultMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    Button("닫기") {
                        showPopup = false
                        scannedCode = "" // 재스캔 허용
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(20)
                .shadow(radius: 10)
            }
        }
    }

    func handleScanned(code: String) {
        // 예시 URL: https://m.dhlottery.co.kr/?v=1100521824362738
        guard let vParam = URLComponents(string: code)?
                .queryItems?.first(where: { $0.name == "v" })?.value else {
            resultMessage = "QR 코드에서 로또 정보를 찾을 수 없습니다."
            showPopup = true
            return
        }

        // 회차 추출 (앞 3자리)
        let round = Int(vParam.prefix(3)) ?? -1

        // 번호 6개 추출
        let numbers = stride(from: 3, to: vParam.count, by: 2).compactMap {
            let start = vParam.index(vParam.startIndex, offsetBy: $0)
            let end = vParam.index(start, offsetBy: 2, limitedBy: vParam.endIndex) ?? vParam.endIndex
            return Int(vParam[start..<end])
        }

        // 당첨 번호 불러오기 예시 (여기선 더미 사용)
        let winningNumbers = [5, 11, 24, 33, 39, 44]    //회차별 당첨 번호를 데이터베이스에서 불러오기
        let bonusNumber = 10

        let matched = numbers.filter { winningNumbers.contains($0) }.count
        let hasBonus = numbers.contains(bonusNumber)

        let rank: String
        switch matched {
        case 6: rank = "경축! 1등 당첨! 농협 본점에서 당첨금을 수령하세요!"
        case 5: rank = hasBonus ? "축! 2등 당첨! 가까운 농협중앙회에서 당첨금을 수령하세요!" : "축! 3등 당첨! 가까운 농협중앙회에서 당첨금을 수령하세요!"
        case 4: rank = "축! 4등 당첨! 판매인으로부터 당첨금을 수령하세요!"
        case 3: rank = "축! 5등 당첨! 판매인으로부터 당첨금을 수령하세요!"
        default: rank = "낙첨입니다."
        }

        resultMessage = """
        회차: \(round)회
        선택번호: \(numbers.map { "\($0)" }.joined(separator: ", "))
        결과: \(rank)
        """
        showPopup = true
    }
}
