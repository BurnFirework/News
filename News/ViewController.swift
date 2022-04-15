//
//  ViewController.swift
//  News
//
//  Created by Арина Соколова on 05.02.2022.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(NewsTableViewCell.self, forCellReuseIdentifier: NewsTableViewCell.identifier)
        return table
    }()
    let refreshControl = UIRefreshControl()
    
    private var articles = [Article]()
    private var viewModels = [NewsTableViewCellViewModel]();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Новости"
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.attributedTitle = NSAttributedString(string: "Загружаем новости")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        let defaults = UserDefaults.standard
        if let data = defaults.value(forKey:"articles") as? Data {
            self.articles = try! PropertyListDecoder().decode(Array<Article>.self, from: data)
            self.viewModels = articles.compactMap({
                NewsTableViewCellViewModel(
                    title: $0.title,
                    subtitle: $0.description ?? "No Description",
                    views: $0.views ?? 0,
                    imageURL: URL(string: $0.urlToImage ?? "")
                )
            })
        } else {
            API.shared.getTopStories { [weak self] result in
                switch result {
                case .success(let articles):
                    self?.articles = articles
                    self?.viewModels = articles.compactMap({
                        NewsTableViewCellViewModel(
                            title: $0.title,
                            subtitle: $0.description ?? "No Description",
                            views: $0.views ?? 0,
                            imageURL: URL(string: $0.urlToImage ?? "")
                        )
                    })
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error)
                }
            }
            defaults.set(try? PropertyListEncoder().encode(articles), forKey: "articles")
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        API.shared.getTopStories { [weak self] result in
            switch result {
            case .success(let articles):
                self?.articles = articles
                self?.viewModels = articles.compactMap({
                    NewsTableViewCellViewModel(
                        title: $0.title,
                        subtitle: $0.description ?? "No Description",
                        views: $0.views ?? 0,
                        imageURL: URL(string: $0.urlToImage ?? "")
                    )
                })
                
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing()
                    self?.tableView.reloadData()
                    let defaults = UserDefaults.standard
                    defaults.set(try? PropertyListEncoder().encode(self?.articles), forKey: "articles")
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let alert = UIAlertController(title: "Ошибка интернет-соединения", message: "Проверьте подключение к интернету", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: UIAlertAction.Style.default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NewsTableViewCell.identifier,
            for: indexPath
        ) as? NewsTableViewCell else {
            fatalError()
        }
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let article = articles[indexPath.row]
        if (article.views == nil) {
            articles[indexPath.row].views = 0
        }
        articles[indexPath.row].views! += 1
        viewModels[indexPath.row].views += 1
        
        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.none)
        
        let defaults = UserDefaults.standard
        defaults.set(try? PropertyListEncoder().encode(articles), forKey: "articles")
        
        guard let url = URL(string: article.url ?? "") else {
            return
        }
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 190
    }
}

