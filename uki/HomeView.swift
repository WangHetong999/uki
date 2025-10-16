//
//  HomeView.swift
//  uki
//
//  主页/欢迎页 - 导航到聊天和设置
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // 顶部 logo/吉祥物
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text("🐲")
                                .font(.system(size: 60))
                        )
                        .shadow(radius: 10)

                    Text("嘎巴龙")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("你的数字陪伴伙伴")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)

                Spacer()

                // 导航按钮
                VStack(spacing: 20) {
                    NavigationLink(destination: ChatView()) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.title2)
                            Text("开始聊天")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }

                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                            Text("设置")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // 底部提示
                Text("🎧 建议佩戴耳机以获得更好体验")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeView()
}
