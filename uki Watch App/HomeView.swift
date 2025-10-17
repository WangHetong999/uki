//
//  HomeView.swift
//  uki Watch App
//
//  主页/欢迎页 - watchOS 精简版
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 顶部 logo/吉祥物
                VStack(spacing: 8) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("🐲")
                                .font(.system(size: 30))
                        )

                    Text("uki")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("你的专属臭宝")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()

                // 导航按钮
                VStack(spacing: 12) {
                    NavigationLink(destination: ChatView()) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.system(size: 16))
                            Text("开始聊天")
                                .font(.system(size: 15))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                Spacer()

                // 底部提示
                Text("🎧 佩戴耳机效果更佳")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    HomeView()
}
