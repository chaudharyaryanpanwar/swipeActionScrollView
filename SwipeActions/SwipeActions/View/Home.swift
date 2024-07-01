//
//  Home.swift
//  SwipeActions
//
//  Created by Aryan Panwar on 28/06/24.
//

import SwiftUI

struct Home: View {
    @State private var colors : [Color]  = [.black , .yellow  , .purple , .brown ]
    var body: some View {
        ScrollView(.vertical){
            LazyVStack(spacing : 10){
                ForEach(colors , id: \.self){ color in
                    SwipeAction(cornerRadius: 15 , direction: .trailing) {
                        CardView(color)
                    } actions: {
                        Action(tint : .blue , icon : "star.fill"){
                            print("Bookmarked")
                        }
                        Action(tint : .red , icon : "trash.fill") {
                            withAnimation(.easeInOut){
                                colors.removeAll(where: { $0 == color})
                            }
                        }
                    }

                }
            }
            .padding(15)
        }
        .scrollIndicators(.hidden)
    }
    
//    SAMPLE CARD VIEW
    @ViewBuilder
    func CardView(_ color : Color)->some View {
        HStack(spacing : 12){
            Circle()
                .frame(width : 50 , height : 50)
            VStack(alignment: .leading, spacing : 6 ,  content: {
                RoundedRectangle(cornerRadius: 5)
                    .frame(width : 80 , height : 5)
                RoundedRectangle(cornerRadius: 5)
                    .frame(width : 60 , height : 5)
            })
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.4))
        .padding(.horizontal , 15)
        .padding(.vertical , 10)
        .background(color.gradient )
    }
}

//CUSTOM SWIPE ACTION VIEW
struct SwipeAction <Content : View> : View {
    var cornerRadius  : CGFloat = 0
    var direction : SwipeDirection  = .trailing
    @ViewBuilder var content : Content
    @ActionBuilder var actions : [Action]
//  VIEW PROPERTIES
//    VIEW UNIQUE ID
    let viewID = UUID()
    @State private var isEnabled : Bool = true
    var body : some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal){
                LazyHStack(spacing : 0){
                    content
                    //to take full availabe space
                        .containerRelativeFrame(.horizontal)
                        .background{
                            if let firstAction = actions.first {
                                Rectangle()
                                    .fill(firstAction.tint)
                            }
                        }
                        .id(viewID)
                    ActionButtons {
                        withAnimation(.snappy){
                            scrollProxy.scrollTo(viewID , anchor: direction == .trailing ? .topLeading : .topTrailing)
                        }
                    }
                }
                .scrollTargetLayout()
                .visualEffect { content, geometryProxy in
                    content
                        .offset(x: scrollOffset(geometryProxy))
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .background{
                if let lastAction = actions.last {
                    Rectangle()
                        .fill(lastAction.tint)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
        }
        .allowsHitTesting(isEnabled)
        .transition(CustomTransition())
    }
    
    //ACTION BUTTONS
    @ViewBuilder
    func ActionButtons(resetPosition : @escaping () -> ()) -> some View {
    //    Each button will have a width of 100 width
        Rectangle()
            .fill(.clear)
            .frame(width : CGFloat(actions.count) * 100)
            .overlay(alignment : direction.alignment){
                HStack(spacing : 0){
                    ForEach(actions){button in
                        Button(action : {
                            Task {
                                isEnabled = false
                                resetPosition()
                                try? await Task.sleep(for : .seconds(0.25))
                                button.action()
                                try? await Task.sleep(for: .seconds(0.1))
                                isEnabled = true
                            }
                        }, label : {
                            Image(systemName: button.icon)
                                .font(button.iconFont)
                                .foregroundStyle(button.iconTint)
                                .frame(width : 100)
                                .frame(maxHeight: .infinity)
                                .contentShape(.rect)
                        })
                        .buttonStyle(.plain)
                        .background(button.tint)
                    }
                }
            }
    }
    
    func scrollOffset(_ proxy : GeometryProxy)->CGFloat {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        
        return direction == .trailing ? (minX>0 ? -minX : 0) : (minX < 0 ? -minX : 0)
    }
}

//STRUCT CUSTOM TRANSITION
struct CustomTransition : Transition {
    func body(content : Content  , phase : TransitionPhase)-> some View {
        content
            .mask{
                GeometryReader {
                    let size = $0.size
                    
                    Rectangle()
                        .offset(y : phase == .identity ? 0 : -size.height)
                }
                .containerRelativeFrame(.horizontal)
            }
    }
}

//SWIPE ACTIONS
enum SwipeDirection {
    case leading
    case trailing
    
    var alignment : Alignment {
        switch self {
        case .leading :
            return .leading
        case .trailing :
            return .trailing
        }
    }
}

//ACTION MODEL
struct Action  : Identifiable {
    private(set) var id : UUID = .init()
    var tint : Color
    var icon : String
    var iconFont : Font = .title3
    var iconTint : Color = .white
    var isEnabled  :Bool = true
    var action : () -> ()
}

@resultBuilder
struct ActionBuilder {
    static func buildBlock(_ components : Action...)->[Action]{
        return components
    }
}

#Preview {
    Home()
}
