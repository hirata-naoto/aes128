// AES-128のS-box（非線形置換テーブル）
const SBOX: [u8; 256] = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
];

const RCON: [u8; 11] = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36];

type State = [[u8; 4]; 4];

struct Aes128 {
    round_keys: [State; 11],
}

impl Aes128 {
    pub fn new(key: &[u8; 16]) -> Self {
        let round_keys = Self::key_expansion(key);
        Self { round_keys }
    }

    fn key_expansion(key: &[u8; 16]) -> [State; 11] {
        let mut w = [[0u8; 4]; 44];
        for i in 0..4 {
            w[i] = [key[4 * i], key[4 * i + 1], key[4 * i + 2], key[4 * i + 3]];
        }

        for i in 4..44 {
            let mut temp = w[i - 1];
            if i % 4 == 0 {
                let t = temp[0];
                temp[0] = temp[1];
                temp[1] = temp[2];
                temp[2] = temp[3];
                temp[3] = t;

                for b in &mut temp {
                    *b = SBOX[*b as usize];
                }
                temp[0] ^= RCON[i / 4];
            }
            for j in 0..4 {
                w[i][j] = w[i - 4][j] ^ temp[j];
            }
        }

        let mut round_keys = [[[0u8; 4]; 4]; 11];
        for r in 0..11 {
            for c in 0..4 {
                round_keys[r][c] = w[r * 4 + c];
            }
        }
        round_keys
    }

    pub fn encrypt(&self, block: &mut [u8; 16]) {
        let mut state = self.bytes_to_state(block);

        self.add_round_key(&mut state, &self.round_keys[0]);

        for round in 1..=9 {
            self.sub_bytes(&mut state);
            self.shift_rows(&mut state);
            self.mix_columns(&mut state);
            self.add_round_key(&mut state, &self.round_keys[round]);
        }

        self.sub_bytes(&mut state);
        self.shift_rows(&mut state);
        self.add_round_key(&mut state, &self.round_keys[10]);

        *block = self.state_to_bytes(&state);
    }

    fn sub_bytes(&self, state: &mut State) {
        for row in state.iter_mut() {
            for byte in row.iter_mut() {
                *byte = SBOX[*byte as usize];
            }
        }
    }

    fn shift_rows(&self, state: &mut State) {
        let temp = state[1][0];
        state[1][0] = state[1][1];
        state[1][1] = state[1][2];
        state[1][2] = state[1][3];
        state[1][3] = temp;

        let temp0 = state[2][0];
        let temp1 = state[2][1];
        state[2][0] = state[2][2];
        state[2][1] = state[2][3];
        state[2][2] = temp0;
        state[2][3] = temp1;

        let temp = state[3][3];
        state[3][3] = state[3][2];
        state[3][2] = state[3][1];
        state[3][1] = state[3][0];
        state[3][0] = temp;
    }

    fn gmul(mut a: u8, mut b: u8) -> u8 {
        let mut p = 0;
        for _ in 0..8 {
            if (b & 1) != 0 {
                p ^= a;
            }
            let hi_bit_set = (a & 0x80) != 0;
            a <<= 1;
            if hi_bit_set {
                a ^= 0x1b;
            }
            b >>= 1;
        }
        p
    }

    fn mix_columns(&self, state: &mut State) {
        for c in 0..4 {
            let s0 = state[0][c];
            let s1 = state[1][c];
            let s2 = state[2][c];
            let s3 = state[3][c];

            state[0][c] = Self::gmul(0x02, s0) ^ Self::gmul(0x03, s1) ^ s2 ^ s3;
            state[1][c] = s0 ^ Self::gmul(0x02, s1) ^ Self::gmul(0x03, s2) ^ s3;
            state[2][c] = s0 ^ s1 ^ Self::gmul(0x02, s2) ^ Self::gmul(0x03, s3);
            state[3][c] = Self::gmul(0x03, s0) ^ s1 ^ s2 ^ Self::gmul(0x02, s3);
        }
    }

    fn add_round_key(&self, state: &mut State, round_key: &State) {
        let r_len = state.len();
        let c_len = state[0].len();
        for r in 0..r_len {
            for c in 0..c_len {
                state[r][c] ^= round_key[r][c];
            }
        }
    }

    fn bytes_to_state(&self, block: &[u8; 16]) -> State {
        let mut state = [[0u8; 4]; 4];
        for i in 0..16 {
            state[i % 4][i / 4] = block[i];
        }
        state
    }

    fn state_to_bytes(&self, state: &State) -> [u8; 16] {
        let mut block = [0u8; 16];
        for i in 0..16 {
            block[i] = state[i % 4][i / 4];
        }
        block
    }
}

fn main() {
    println!("テストを実行するには `cargo test` を実行してください。");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nist_fips_197_vector() {
        // NIST公式のテストベクタ
        let key: [u8; 16] = [
            0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
            0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
        ];
        let mut plaintext: [u8; 16] = [
            0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
            0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
        ];
        let expected_ciphertext: [u8; 16] = [
            0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60,
            0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97,
        ];

        let aes = Aes128::new(&key);
        aes.encrypt(&mut plaintext);

        // 結果が一致するか検証
        assert_eq!(
            plaintext, expected_ciphertext,
            "\n暗号化結果がNISTのテストベクタと一致しません！\n出力: {:02x?}\n期待: {:02x?}",
            plaintext, expected_ciphertext
        );

        println!("NISTテストベクタの検証に成功しました！");
    }
}
