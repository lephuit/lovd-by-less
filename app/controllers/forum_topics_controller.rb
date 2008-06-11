##
# ForumTopicsController
# Author: Les Freeman (lesliefreeman3@gmail.com)
# Created on: 5/16/08
# Updated on: 6/4/08
#

class ForumTopicsController < ApplicationController
  
  helper ForumsHelper
  
  skip_filter :login_required, :only => [:show, :index]
  before_filter :setup
  
  def show
    ##
    # if the validation of a followup post failed, it is stored in the session by the ForumPostsController
    if session[:new_forum_post]
      @post = session[:new_forum_post]
      session[:new_forum_post] = nil
    else
      @post = @topic.posts.new
    end
    
    @posts = @topic.posts.paginate(:all, :page => params[:page], :order => 'created_at ASC')
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @topic }
    end
  end

  def new
    @post = @topic.posts.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @topic }
    end
  end

  def edit
  end

  def create
    @topic = @forum.topics.build(params[:forum_topic])
    @topic.owner = @p
    
    @post = ForumPost.new(params[:forum_post])
    @post.owner = @p
    @topic.posts << @post
    
    
    respond_to do |format|
      if @topic.save
        flash[:notice] = 'ForumTopic was successfully created.'
        format.html { redirect_to(forum_topic_url(@forum, @topic)) }
        format.xml  { render :xml => @topic, :status => :created, :location => @topic }
        format.js do
          render :update do |page|
            page.insert_html :after, "topic_labels_row", :partial => 'forum_topics/topic', :object => @topic
            page << "tb_init('\##{dom_id(@topic)}_edit_link')"
            page << "tb_remove()"
            page.visual_effect :highlight, dom_id(@topic)
          end
        end
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @topic.errors, :status => :unprocessable_entity }
        format.js do
          render :update do |page|
            if !@post.errors.empty?
              page.alert @post.errors.to_s
            elsif !@topic.errors.empty?
              page.alert @topic.errors.to_s
            end
          end
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @topic.update_attributes(params[:forum_topic])
        format.html do 
          flash[:notice] = 'ForumTopic was successfully updated.'
          redirect_to(forum_path(@topic.forum)) 
        end
        format.xml  { head :ok }
        format.js do
          render :update do |page|
            page.replace dom_id(@topic), :partial => 'forum_topics/topic', :object => @topic
            page << "tb_init('\##{dom_id(@topic)}_edit_link')"
            page << "tb_remove()"
            page << "$('TB_ajaxContent').innerHTML = ''" #otherwise we get double content on next show
            page.visual_effect :highlight, dom_id(@topic)
          end
        end
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @topic.errors, :status => :unprocessable_entity }
        format.js do
          render :update do |page|
            page.alert @topic.errors.to_s
          end
        end
      end
    end
  end

  def destroy
    @topic.destroy

    respond_to do |format|
      format.html { redirect_to(@forum) }
      format.xml  { head :ok }
      format.js do
        if @topic.frozen?
          render :update do |page|
            page.visual_effect :puff, dom_id(@topic)
          end
        end
      end
    end
  end
  
private

  def setup
    @forum = Forum.find(params[:forum_id])
    if params[:id]
      @topic = @forum.topics.find(params[:id])
    else
      @topic = ForumTopic.new
    end
  end

  def allow_to
    super :admin, :all => true
    super :user, :only => [:new, :create]
    super :all, :only => [:index, :show]
  end

end