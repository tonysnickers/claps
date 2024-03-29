class GroupsController < ApplicationController
  before_action :set_group, only: [:show, :update, :compute_results, :results]

  def index
    @groups = policy_scope(Group)
  end

  def show
    authorize @group
    if !OrderedChoice.where(group: @group).empty?
      @final = find_result
    end
  end

  def new
    @solo = params[:solo]
    @group = Group.new
    authorize @group
    @group_user = GroupUser.new
    @friends = []
    @friends << current_user.friends.map(&:users_friend)
    @friends << Friend.where(users_friend: current_user).map(&:user)
    @friends.flatten!
  end

  def create
    @group = Group.new(params_group)
    @group.user = current_user
    authorize @group
    @friends = []
    @friends << current_user.friends.map(&:users_friend)
    @friends << Friend.where(users_friend: current_user).map(&:user)
    @friends.flatten!
    if params["group"]["user_id"]
      if (params["group"]["user_id"].count > 0) && @group.save
        @user_ids = params[:group][:user_id]
        @user_ids.each do |id|
          group_user = GroupUser.new(user_id: id, group_id: @group.id)
          group_user.save
        end
        group_user = GroupUser.new(user_id: current_user.id, group_id: @group.id)
        group_user.save
        redirect_to group_path(@group)
      else
        render :new
      end
    else
      if @group.save
        group_user = GroupUser.new(user_id: current_user.id, group_id: @group.id)
        group_user.save
        redirect_to group_path(@group)
      else
        render :new
      end
    end
  end

  def update
    authorize @group
    @group.update(archive: true)
    redirect_to groups_path, status: :see_other
  end

  def compute_results
    if params["ordered_choice"]["movie_order"].split(',').length == 1
      @ids = params["ordered_choice"]["movie_order"].split(' ')
    else
      @ids = params["ordered_choice"]["movie_order"].split(',')
    end
    authorize @group
    @points = [5, 4, 3, 2, 1]
    @ids.each do |movie_id|
      if OrderedChoice.find_by(movie: Movie.find(movie_id.to_i), group: @group)
        oc = OrderedChoice.find_by(movie: Movie.find(movie_id.to_i), group: @group)
        oc.update(point: oc.point += @points[@ids.index(movie_id)])
      else
        OrderedChoice.create(movie: Movie.find(movie_id.to_i), group: @group, point: @points[@ids.index(movie_id)])
      end
    end
    h = {}
    OrderedChoice.where(group: @group).each do |oc|
      h[oc.movie_id] = oc.point
    end
    @final = Movie.find(h.sort_by {|k, v| v}.reverse.first.first)

    @group.total_points = OrderedChoice.where(group: @group).sum(:point)
    # @group.points_to_achieve = @group.group_users.count * 15
    @group.save

    if (@group.points_to_achieve - @group.total_points) > 1
      redirect_to group_movies_path(@group, wait_for_the_others: true)
    else
      redirect_to results_group_path(@group)
    end
  end

  def results
    authorize @group
    @final = find_result
  end

  private

  def find_result
    h = {}
    OrderedChoice.where(group: @group).each do |oc|
      h[oc.movie_id] = oc.point
    end
    return Movie.find(h.sort_by {|k, v| v}.reverse.first.first)
  end

  def set_group
    @group = Group.find(params[:id])
  end

  def params_group
    params.require(:group).permit(:name)
  end
end
