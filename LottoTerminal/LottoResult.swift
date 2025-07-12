//
//  LottoResult.swift
//  LottoTerminal
//
//  Created by sorak azae on 7/11/25.
//


import Foundation

struct LottoResult: Codable {
    let drwNo: Int
    let drwtNo1: Int
    let drwtNo2: Int
    let drwtNo3: Int
    let drwtNo4: Int
    let drwtNo5: Int
    let drwtNo6: Int
    let bnusNo: Int
}

func fetchLottoResult(for round: Int, completion: @escaping (LottoResult?) -> Void) {
    let urlStr = "https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo=\(round)"
    guard let url = URL(string: urlStr) else {
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: url) { data, response, error in
        guard
            error == nil,
            let data = data,
            let result = try? JSONDecoder().decode(LottoResult.self, from: data),
            result.drwNo == round,
            result.drwtNo1 != 0 // 당첨번호가 비어있지 않은지 체크
        else {
            completion(nil) // 실패로 간주
            return
        }
        completion(result)
    }.resume()
}
