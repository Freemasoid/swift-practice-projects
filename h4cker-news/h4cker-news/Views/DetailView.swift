//
//  DetailView.swift
//  h4cker-news
//
//  Created by Roman on 21.05.2025.
//

import SwiftUI

struct DetailView: View {
    
    let url: String?
    
    var body: some View {
        WebView(urlString: url)
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(url: "https://wwww.google.com")
    }
}
