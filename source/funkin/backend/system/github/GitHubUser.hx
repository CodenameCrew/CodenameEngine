package funkin.backend.system.github;

typedef GitHubUser = {
	/**
	 * Username of the user.
	 */
	var login:String;

	/**
	 * ID of the user.
	 */
	var id:Int;

	/**
	 * ID of the current node on the GitHub database.
	 */
	var node_id:String;

	/**
	 * Link to the avatar (profile picture).
	 */
	var avatar_url:String;

	/**
	 * Unknown
	 */
	var gravatar_id:String;

	/**
	 * URL to the user on GitHub's servers.
	 */
	var url:String;

	/**
	 * URL to the user on GitHub's website.
	 */
	var html_url:String;

	/**
	 * URL on GitHub's API to access this user's followers.
	 */
	var followers_url:String;

	/**
	 * URL on GitHub's API to access the accounts this user is following.
	 */
	var following_url:String;

	/**
	 * URL on GitHub's API to access this user's gists.
	 */
	var gists_url:String;

	/**
	 * URL on GitHub's API to access this user's starred repositories.
	 */
	var starred_url:String;

	// NOT COMPLETE: MISSING repos_url, organizations_url, subscriptions_url, events_url, received_events_url.

	/**
	 * Type of the user.
	 */
	var type:GitHubUserType;

	/**
	 * Whenever the user is a GitHub administrator.
	 */
	var site_admin:Bool;

	/**
	 * Name of the user.
	 */
	var name:String;

	/**
	 * The company this user belongs to. Can be `null`.
	 */
	var company:String;

	var blog:String;

	var location:String;

	var email:String;

	var hireable:Null<Bool>;

	var bio:String;

	/**
	 * Twitter username of the user. Can be null.
	 */
	var twitter_username:String;

	/**
	 * Number of public repos this user own.
	 */
	var public_repos:Int;

	/**
	 * Number of public gists this user own.
	 */
	var public_gists:Int;

	/**
	 * Number of followers this user have
	 */
	var followers:Int;

	/**
	 * Number of accounts this user follows.
	 */
	var following:Int;

	/**
	 * Date of creation of the account
	 */
	var created_at:String;

	/**
	 * Date of last account update.
	 */
	var updated_at:String;
}

enum abstract GitHubUserType(String) {
	var USER = "User";
	var ORGANIZATION = "Organization";
}