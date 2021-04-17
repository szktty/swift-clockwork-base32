import Foundation

public struct Base32 {
    
    private class Buffer {
        var data: Data
        var length: Int
        var input: Data
        var output: Data
        var alignment: Alignment
        var roundCount: Int
        
        init(data: Data, alignment: Alignment) {
            self.data = data
            self.alignment = alignment
            length = getBufferLength(of: data, unit: alignment.rawValue)
            input = Data(repeating: 0, count: length)
            input.withUnsafeMutableBytes { bytes -> Void in
                data.copyBytes(to: bytes, count: data.count)
                return ()
            }
            output = Data(repeating: 0,
                          count: length * alignment.reverse.rawValue / alignment.rawValue)
            roundCount = length / alignment.rawValue
        }
        
        func round(_ handler: (Int, Int) -> Bool) -> Bool {
            for i in 0..<roundCount {
                if !handler(i * alignment.rawValue, i * alignment.reverse.rawValue) {
                    return false
                }
            }
            return true
        }
        
    }
    
    private static func getBufferLength(of data: Data, unit: Int) -> Int {
        (data.count / unit + (data.count % unit > 0 ? 1 : 0)) * unit
    }
    
    public static func encode(_ data: Data) -> Data {
        let buffer = Buffer(data: data, alignment: .encode)
        _ = buffer.round { j, k in
            buffer.output[k] = encodeSymbols[Int(buffer.input[j]) >> 3 & 0x1F]
            buffer.output[k+1] = encodeSymbols[((Int(buffer.input[j]) & 0x07) << 2) |
                (Int(buffer.input[j+1]) >> 6 & 0x03)]
            buffer.output[k+2] = encodeSymbols[Int(buffer.input[j+1]) >> 1 & 0x1F]
            buffer.output[k+3] = encodeSymbols[((Int(buffer.input[j+1]) & 0x01) << 4) |
                (Int(buffer.input[j+2]) >> 4 & 0x0F)]
            buffer.output[k+4] = encodeSymbols[((Int(buffer.input[j+2]) & 0x0F) << 1) |
                (Int(buffer.input[j+3]) >> 7 & 0x01)]
            buffer.output[k+5] = encodeSymbols[Int(buffer.input[j+3]) >> 2 & 0x1F]
            buffer.output[k+6] = encodeSymbols[((Int(buffer.input[j+3]) & 0x03) << 3) |
                (Int(buffer.input[j+4]) >> 5 & 0x07)]
            buffer.output[k+7] = encodeSymbols[Int(buffer.input[j+4]) & 0x1F]
            return true
        }
        
        let length = data.count * 8 / 5 + (data.count * 8 % 5 > 0 ? 1 : 0)
        var ret = Data(repeating: 0, count: length)
        ret.withUnsafeMutableBytes { bytes -> Void in
            buffer.output.copyBytes(to: bytes, count: length)
            return ()
        }
        return ret
    }
    
    enum Alignment: Int {
        case encode = 5
        case decode = 8
        
        var reverse: Alignment {
            switch self {
            case .encode:
                return .decode
            default:
                return .encode
            }
        }
        
    }
    
    private static func createBuffer(from data: Data, alignment: Alignment) -> (Data, Data) {
        let length = getBufferLength(of: data, unit: alignment.rawValue)
        var input = Data(repeating: 0, count: length)
        input.withUnsafeMutableBytes { bytes -> Void in
            data.copyBytes(to: bytes, count: data.count)
            return ()
        }
        let output = Data(repeating: 0,
                          count: length * alignment.reverse.rawValue / alignment.rawValue)
        return (input, output)
    }
    
    public static func decode(_ data: Data) -> Data? {
        let buffer = Buffer(data: data, alignment: .decode)
        let result = buffer.round { j, k in
            let d0 = decodeSymbols[Int(buffer.input[j])]
            let d1 = decodeSymbols[Int(buffer.input[j+1])]
            let d2 = decodeSymbols[Int(buffer.input[j+2])]
            let d3 = decodeSymbols[Int(buffer.input[j+3])]
            let d4 = decodeSymbols[Int(buffer.input[j+4])]
            let d5 = decodeSymbols[Int(buffer.input[j+5])]
            let d6 = decodeSymbols[Int(buffer.input[j+6])]
            let d7 = decodeSymbols[Int(buffer.input[j+7])]
            if d0 < 0 || d1 < 0 || d2 < 0 || d3 < 0 || d4 < 0 || d5 < 0 || d6 < 0 || d7 < 0 {
                return false
            }
            buffer.output[k] = UInt8(Int(d0 << 3) | Int(d1 >> 2 & 0x07))
            buffer.output[k+1] = UInt8(Int((d1 & 0x03) << 6) | Int(d2 << 1) | Int(d3 >> 4 & 0x01))
            buffer.output[k+2] = UInt8(Int((d3 & 0x0F) << 4) | Int(d4 >> 1 & 0x0F))
            buffer.output[k+3] = UInt8(Int((d4 & 0x01) << 7) | Int(d5 << 2) | Int(d6 >> 3 & 0x03))
            buffer.output[k+4] = UInt8(Int((d6 & 0x07) << 5) | d7)
            return true
        }
        if result {
            let length = data.count * 5 / 8
            var ret = Data(repeating: 0, count: length)
            ret.withUnsafeMutableBytes { bytes -> Void in
                buffer.output.copyBytes(to: bytes, count: length)
                return ()
            }
            return ret
        } else {
            return nil
        }
    }
    
}

let encodeSymbols: [UInt8] = [
    // '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
    // 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K',
    65, 66, 67, 68, 69, 70, 71, 72, 74, 75,
    // 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X',
    77, 78, 80, 81, 82, 83, 84, 86, 87, 88,
    // 'Y', 'Z',
    89, 90
]

let decodeSymbols: [Int] = [
    0, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 0-9 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 10-19 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 20-29 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 30-39 */
    -1, -1, -1, -1, -1, -1, -1, -1, 0, 1, /* 40-49 */
    2, 3, 4, 5, 6, 7, 8, 9, 0, -1, /* 50-59 */
    -1, -1, -1, -1, -1, 10, 11, 12, 13, 14, /* 60-69 */
    15, 16, 17, 1, 18, 19, 1, 20, 21, 0, /* 70-79 */
    22, 23, 24, 25, 26, -2, 27, 28, 29, 30, /* 80-89 */
    31, -1, -1, -1, -1, -1, -1, 10, 11, 12, /* 90-99 */
    13, 14, 15, 16, 17, 1, 18, 19, 1, 20, /* 100-109 */
    21, 0, 22, 23, 24, 25, 26, -1, 27, 28, /* 110-119 */
    29, 30, 31, -1, -1, -1, -1, -1, -1, -1, /* 120-129 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 130-109 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 140-109 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 150-109 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 160-109 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 170-109 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 180-109 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 190-109 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 200-209 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 210-209 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 220-209 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 230-209 */
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, /* 240-209 */
    -1, -1, -1, -1, -1, -1, /* 250-256 */
]
