//
//  Field.swift
//  Backlogger
//
//  Created by Alex Busman on 2/21/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import Foundation

enum GenericFields: String {
    case ApiDetailUrl  = "api_detail_url"
    case Id            = "id"
    case Name          = "name"
    case SiteDetailUrl = "site_detail_url"
}

class Field {
    var apiDetailUrl:  String?
    var idNumber:      Int?
    var name:          String?
    var siteDetailUrl: String?
    
    required init(json: [String : Any]) {
        self.apiDetailUrl  = json[GenericFields.ApiDetailUrl.rawValue]  as? String
        self.idNumber      = json[GenericFields.Id.rawValue]            as? Int
        self.name          = json[GenericFields.Name.rawValue]          as? String
        self.siteDetailUrl = json[GenericFields.SiteDetailUrl.rawValue] as? String
    }
}
