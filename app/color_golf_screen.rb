class ColorGolfScreen < UI::Screen
  attr_accessor :game

  include ViewGeneration

  def on_show
    self.navigation.hide_bar
  end

  def new_game
    rgb_options = available_percentages.map { |t| t[0] }
    @game = Game.new(
      colors_options_r: rgb_options,
      colors_options_g: rgb_options,
      colors_options_b: rgb_options)
  end

  def on_load
    $self = self
    load_game
    render_view
    update
  end

  def update
    get_view(:hole).text = "Hole #{game.hole} of 9"
    get_view(:target_color).background_color = game.target_color
    get_view(:player_color).background_color = game.player_color || :white

    if game.player_color
      get_view(:player_color).text = " "
    else
      get_view(:player_color).text = "?"
    end

    cell_ids.each do |k, v|
      if(v[:value] == game.send(v[:prop]))
        get_view(k).background_color = white_smoke
      else
        get_view(k).background_color = :white
      end
    end

    get_view(:next_hole_button).hidden = !game.correct?
    get_view(:new_game_button).title = "Final Score: #{game.score}, Go Again"

    if game.over?
      get_view(:next_hole_button).hidden = true
      get_view(:new_game_button).hidden = false
    else
      get_view(:new_game_button).hidden = true
    end

    get_view(:final_score).text = "Score: #{@game.score_string}"

    save_game
  end

  def available_percentages
    @available_percentages ||= [["ff", "100%"],
                                ["bf", "75%"],
                                ["80", "50%"],
                                ["3f", "25%"],
                                ["00", "0%"]]
  end

  def cell_ids
    return @cell_ids if @cell_ids

    @cell_ids = Hash.new

    available_percentages.each do |tuple|
      @cell_ids["r_#{tuple[0]}".to_sym] = { method: :swing_for_r, prop: :player_color_r, value: tuple[0], text: tuple[1] }
      @cell_ids["g_#{tuple[0]}".to_sym] = { method: :swing_for_g, prop: :player_color_g, value: tuple[0], text: tuple[1] }
      @cell_ids["b_#{tuple[0]}".to_sym] = { method: :swing_for_b, prop: :player_color_b, value: tuple[0], text: tuple[1] }
    end

    @cell_ids
  end

  def render_view
    view.flex = 1
    view.margin = 5

    render_hole
    render_final_score
    render_target_color_square
    render_player_color_square
    render_next_hole_new_game_button
    render_rgb_grid

    view.update_layout
  end

  def render_hole
    render :hole, UI::Label do |hole|
      hole.text = "Hole #{game.hole} of 9"
      hole.margin = [45, 10, 5, 10]
      hole.text_alignment = :center
    end
  end

  def render_target_color_square
    render :target_color_wraper, UI::View do |header|
      header.margin = 5
      render :target_color_border, UI::View do |border|
        border.background_color = :silver
        border.width = 72
        border.height = 72
        border.align_self = :center
        render :target_color, UI::View do |square|
          square.width = 70
          square.height = 70
          square.margin = 1
          square.align_self = :center
        end
      end
    end
  end

  def render_player_color_square
    render :player_color_wraper, UI::View do |header|
      header.margin = 5
      render :player_color_border, UI::View do |border|
        border.background_color = :silver
        border.width = 72
        border.height = 72
        border.align_self = :center
        render :player_color, UI::Label do |square|
          square.width = 70
          square.height = 70
          square.margin = 1
          square.align_self = :center
          square.text_alignment = :center
          square.font = font.merge({ size: 30 })
        end
      end
    end
  end

  def render_rgb_grid
    header_width = width_for(:target_color_wraper)

    cell_width = (header_width - 30).fdiv(3)

    render :grid, UI::View do |grid|
      grid.width = header_width
      grid.margin = 5
      grid.flex_direction = :row
      grid.flex_wrap = :wrap
      grid.justify_content = :center
      grid.align_self = :center

      render :r_header, UI::Label do |label|
        label.width = cell_width
        label.text = "Red"
        label.align_self = :center
        label.text_alignment = :center
      end

      render :g_header, UI::Label do |label|
        label.width = cell_width
        label.text = "Green"
        label.align_self = :center
        label.text_alignment = :center
      end

      render :b_header, UI::Label do |label|
        label.width = cell_width
        label.text = "Blue"
        label.align_self = :center
        label.text_alignment = :center
      end

      cell_ids.each do |k, v|
        render_rgb_button k, v[:method], v[:value], v[:text], cell_width
      end
    end
  end

  def render_rgb_button id, target_swing, value, text, width
    render id, UI::Button do |button|
      button.width = width
      button.margin = 1
      button.padding = 1
      button.title = text
      button.on :tap do
        game.send(target_swing, value)
        update
      end
      button.background_color = :white
    end
  end

  def render_next_hole_new_game_button
    render :next_hole_button, UI::Button do |button|
      button.title = "Next Hole"
      button.color = bluish
      button.font = font.merge({ size: 20 })
      button.on :tap do
        game.next_hole
        update
      end
    end

    render :new_game_button, UI::Button do |button|
      button.title = "Go Again"
      button.color = bluish
      button.font = font.merge({ size: 20 })
      button.on :tap do
        new_game
        update
      end
    end
  end

  def render_final_score
    render :final_score, UI::Label do |label|
      label.text_alignment = :center
    end
  end

  def font
    { name: 'Existence-Light', size: 18, extension: :otf }
  end

  def bluish
    "2a5db0"
  end

  def white_smoke
    "f5f5f5"
  end

  def save_game
    Store["hole"] = game.hole
    Store["swings"] = game.swings
    Store["player_color_r"] = game.player_color_r
    Store["player_color_g"] = game.player_color_g
    Store["player_color_b"] = game.player_color_b
    Store["target_color_r"] = game.target_color_r
    Store["target_color_g"] = game.target_color_g
    Store["target_color_b"] = game.target_color_b
  end

  def load_game
    new_game
    game.hole = Store["hole"] || game.hole
    game.swings = Store["swings"] || game.swings
    game.player_color_r = Store["player_color_r"] || game.player_color_r
    game.player_color_g = Store["player_color_g"] || game.player_color_g
    game.player_color_b = Store["player_color_b"] || game.player_color_b
    game.target_color_r = Store["target_color_r"] || game.target_color_r
    game.target_color_g = Store["target_color_g"] || game.target_color_g
    game.target_color_b = Store["target_color_b"] || game.target_color_b
  end
end
