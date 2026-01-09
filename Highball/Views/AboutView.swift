import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App icon and name
                VStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 80, height: 80)

                    Text("Highball")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Railway deployment monitoring")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("Version \(version)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 20)

                Divider()
                    .padding(.horizontal, 40)

                // Why Highball
                VStack(alignment: .leading, spacing: 8) {
                    Label("Why \"Highball\"?", systemImage: "light.beacon.max")
                        .font(.headline)

                    Text("In railroad terminology, a highball is a signal meaning \"all clear - proceed at full speed.\" When you see that green icon in your menu bar, you've got a highball.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 40)

                // Team
                VStack(alignment: .leading, spacing: 16) {
                    Label("The Team", systemImage: "person.2")
                        .font(.headline)

                    HStack(spacing: 16) {
                        // Ron
                        VStack(spacing: 8) {
                            Image("RonPhoto")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())

                            Text("Ron Clarkson")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Product Manager")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Claude
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.gradient)
                                    .frame(width: 60, height: 60)

                                Text("C")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }

                            Text("Claude")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Technical Lead")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Text("Built with Claude Code - an exploration of human-AI collaboration in software development.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 40)

                // Links
                VStack(spacing: 12) {
                    Button {
                        openURL(URL(string: "https://github.com/padaron/highball")!)
                    } label: {
                        Label("View on GitHub", systemImage: "link")
                    }
                    .buttonStyle(.link)

                    Button {
                        openURL(URL(string: "https://railway.com")!)
                    } label: {
                        Label("Railway", systemImage: "train.side.front.car")
                    }
                    .buttonStyle(.link)
                }

                Divider()
                    .padding(.horizontal, 40)

                // Attributions
                VStack(spacing: 8) {
                    Text("Attributions")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Button {
                        openURL(URL(string: "http://www.freesoundslibrary.com")!)
                    } label: {
                        Text("Train whistle sound: Free Sounds Library (CC BY 4.0)")
                            .font(.caption2)
                    }
                    .buttonStyle(.link)
                }

                Spacer()

                Text("MIT License")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 16)
            }
        }
        .frame(width: 320, height: 520)
    }
}
