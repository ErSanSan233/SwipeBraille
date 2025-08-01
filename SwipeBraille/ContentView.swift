//
//  ContentView.swift
//  SwipeBraille
//
//  Created on 2025/1/7.
//

import SwiftUI

struct ContentView: View {
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("盲文滑动输入法")
                .font(.title)
                .fontWeight(.bold)
            
            // 说明文字
            Text("请在下方输入框中测试键盘")
                .foregroundColor(.gray)
            
            // 文本输入框
            TextField("点击这里开始输入...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .frame(maxWidth: 300)
            
            // 显示输入的内容
            VStack(alignment: .leading) {
                Text("输入内容：")
                    .font(.headline)
                Text(inputText)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding()
            
            Spacer()
            
            // 使用说明
            Text("提示：请在系统设置中启用键盘")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
